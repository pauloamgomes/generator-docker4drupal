#!/bin/bash
#
# <%= instance %>.sh - helper script for handling docker-sync and docker-compose
#                    start/stop commands.
#                    It also provides a shell option for the php container.
#
# Author: Paulo Gomes <www.pauloamgomes.net>
#
# Changelog:
#
#       20.08.2017 - initial release
#       28.07.2018 - inclusion of new commands
#

DRUPAL_MODE="<%= genType %>"
DOCKER_SYNC="<%= dockerSync %>"

usage() {
  cat <<-EOF

    USAGE: ./<%= instance %>.sh [OPTIONS]

    OPTIONS

      start       Starts docker containers.
      stop        Stops docker containers.
      restart     Stops and starts the containers.
      shell       Opens a bash shell in the docker php container.
                  Use ./<%= instance %>.sh shell root to run as root.
      status      Display status of running containers.
      hosts       Add container endpoints to /etc/hosts file (requires sudo).
                  Use sudo ./<%= instance %>.sh hosts
      sysinstall  Installs <%= instance %>.sh script in /usr/local/bin/<%= instance %>
                  so it can be used as <%= instance %> <command>
      recreate    Recreates all containers (ALL DATA WILL BE ERASED)
      composer    Run composer command inside php container
      drush       Run drush command inside php container
      drupal      Run drupal console command inside php container
      install     Forces installation of drupal
      enable      Install a module using composer and drush
      disable     Disable and uninstall a drupal module
      update      Perform a composer update followed by a drush cim
      db-backup   Creates a database dump
      db-restore  Restores a database dump
      db-cli      Opens the mysql cli
      phplogs     Display in foreground php logs from the php container
EOF

  if [ x"$DOCKER_SYNC" == x"" ]; then
    cat <<-EOF
      dslogs      Display in foreground docker sync logs
      resync      Destroys current sync containers forcing a full resync
EOF
  fi
  echo
}

showHelp() {
  usage
  commands
  exit 0
}

commands() {
  cat <<-EOF

    To check docker-sync logs execute:
      tail -f docker/.docker-sync/daemon.log

    To check docker-compose logs execute:
      $ cd docker; docker-compose logs -f

EOF
}

exitError() {
  echo
  echo "Fatal Error: $@"
  echo
  exit 1
}

start() {
  if [ x"$DOCKER_SYNC" == x"" ]; then
    echo "Starting docker-sync..."
    docker-sync start || exitError "Error initializing docker-sync"
    echo "Done!"
  fi
  echo
  echo "Starting docker-compose..."
  docker-compose up -d || exitError "Error initializing docker-compose"
  echo "Done!"
  echo
  # On first run give some time for full docker sync ends.
  if [ ! -d "../docroot/web/modules" ]; then
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "First execution. Docker is doing a full sync!"
    echo "It can take 1 minute or more, please wait..."
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    sleep 120
    if [ $DRUPAL_MODE == "vanilla" ]; then
      echo
      echo "Installing Drupal..."
      install
      echo
      echo "Drupal installed"
      echo
      echo " username: admin"
      echo " password: admin"
    fi
  fi
  echo
  status
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo
  commands
  echo
}

install() {
  docker-compose exec --user=82 php-<%= instance %> drush -r /var/www/html/web si standard --db-url=mysql://drupal:drupal@mariadb-<%= instance %>/drupal --account-name=admin --account-pass=admin --site-name="<%= siteName %>" -y
}

enable() {
  if [ x"$1" == x"" ]; then
    exitError "Module name is missing"
  else
    if [ ! -d "../docroot/web/modules/contrib/$1" ] && [ ! -d "../docroot/web/themes/contrib/$1" ]; then
        echo "Module not found, trying to download with composer..."
        composer require drupal/$1
    fi
    drush en $1
    drush cr
  fi
}

disable() {
  if [ x"$1" == x"" ]; then
    exitError "Module name is missing"
  else
    drush pm-uninstall $1 && composer remove drupal/$1
    drush cr
  fi
}

drush() {
  docker-compose exec --user=1000 php-<%= instance %> drush -r /var/www/html/web $@
}

drupal() {
  docker-compose exec --user=1000 php-<%= instance %> drupal $@
}

composer() {
  docker-compose exec --user=1000 php-<%= instance %> composer $@
}

update() {
  echo
  echo "Running composer update to update any missing drupal dependency"
  echo
  composer update
  echo
  echo "Running drush cim to import configurations"
  echo
  drush cim
}

stop() {
  echo "Stopping docker-compose..."
  docker-compose stop || exitError "error stopping docker-compose"
  echo "Done!"
  if [ x"$DOCKER_SYNC" == x"" ]; then
    echo "Stopping docker-sync..."
    docker-sync stop || exitError "error stopping docker-sync"
    echo "Done!"
  fi
  echo
}

shell() {
  echo
  echo "Opening bash shell for container php-<%= instance %>"
  echo
  if [ x"$1" == x"root" ]; then
    docker-compose exec --user=root php-<%= instance %> bash
  else
    docker-compose exec --user=1000 php-<%= instance %> bash
  fi
}

phplogs() {
  docker-compose logs -f | egrep "<%= instance %>_php"
}

dslogs() {
  tail -100f .docker-sync/daemon.log
}

hosts() {
  echo
  echo "Updating /etc/hosts file with docker entries"
  echo
  echo "# drupal4docker - <%= siteName %>"
  echo "Adding <%= domain %> -> 127.0.0.1" >> /etc/hosts
  echo -e "127.0.0.1\t<%= domain %>" >> /etc/hosts
  echo "Adding mailhog.<%= domain %> -> 127.0.0.1"
  echo -e "127.0.0.1\t<%= domain %>" >> /etc/hosts
  echo "Adding pma.<%= domain %> -> 127.0.0.1"
  echo -e "127.0.0.1\tpma.<%= domain %>" >> /etc/hosts
  echo "# END OF drupal4docker entries" >> /etc/hosts
  echo
}

status() {
  echo
  echo " Available endpoints:"
  echo
  echo " Drupal      http://<%= domain %>"
  echo " Mailhog     http://mailhog.<%= domain %>"
  echo " PhpMyAdmin  http://pma.<%= domain %>"
  echo
  echo " Status of running containers for MMR"
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Size}}\t{{.Status}}" | grep "<%= instance %>" | grep -v CONTAINER
  echo
  echo
}

recreate() {
  echo "Removing containers"
  docker-compose down
  echo "Cleaning docker syncs"
  docker-sync clean
}

resync() {
  echo
  echo "Removing sync containers"
  echo
  stop
  docker volume rm sync-<%= instance %> 2>&1 >/dev/null | sed "s/.*- \[//g" | sed "s/\]//g" | sed "s/ //g"  | tr ',' '\n' | xargs docker rm
  docker volume rm sync-certs-<%= instance %> 2>&1 >/dev/null | sed "s/.*- \[//g" | sed "s/\]//g" | sed "s/ //g"  | tr ',' '\n' | xargs docker rm
  echo
  echo
  docker-sync clean
  echo
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "Sync containers and volumes removed"
  echo
  start
}

COMMAND=`echo $1 | sed 's/^[^=]*=//g'`

echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo " <%= instance %>.sh command helper for <%= siteName %>"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo

if [ ! -f "docker/docker-compose.yml" ]; then
  exitError "missing docker compose file - docker/docker-compose.yml"
fi

if [ x"$DOCKER_SYNC" == x"" ] && [ ! -f "docker/docker-sync.yml" ]; then
  exitError "missing docker sync file - docker/docker-sync.yml"
fi

shift
cd docker

case "$COMMAND" in
 start)
  start
  ;;
 stop)
  stop
  ;;
 restart)
  stop
  start
  ;;
 shell)
  shell $@
  ;;
 status)
  status
  ;;
 hosts)
  hosts
  ;;
 recreate)
  recreate
  ;;
 drush)
  drush $@
  ;;
 drupal)
  drupal $@
  ;;
 composer)
  composer $@
  ;;
 install)
  install
  ;;
 enable)
  enable $@
  ;;
 disable)
  disable $@
  ;;
 db-backup)
  ./mysql.sh backup
  ;;
 db-restore)
  ./mysql.sh restore $@
  ;;
 db-cli)
  ./mysql.sh cli
  ;;
 update)
  update
  ;;
 styles)
  styles
  ;;
 dlogs)
  dlogs
  ;;
 dslogs)
  dslogs
  ;;
 help)
  showHelp
  ;;
 sysinstall)
  cd ..
  if [ ! -f /usr/local/bin/<%= instance %> ]; then
    ln -s $PWD/<%= instance %>.sh /usr/local/bin/<%= instance %> && echo "<%= instance %>.sh script installed in /usr/local/bin/<%= instance %>" || echo "System error during linking <%= instance %>.sh to /usr/local/bin/<%= instance %>"
  else
    echo "already installed!"
  fi
  ;;
 resync)
  resync
  ;;
 *)
  if [ x"$COMMAND" != x"" ]; then
    echo "ERROR: unknown command \"$COMMAND\""
  fi
  usage
  exit 1
  ;;
esac

exit 0
