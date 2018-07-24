#!/bin/bash
#
# mysql.sh - helper script for running mysql operations
#
# Author: Paulo Gomes <www.pauloamgomes.net>
#
# Changelog:
#
#       22.10.2017 - initial release

usage() {
  cat <<-EOF

    USAGE: ./mysql.sh [OPTIONS]

    OPTIONS

      backup    Creates a backup of current drupal database
      restore   Restores a previous backup
      cli       Opens an mysql shell

EOF
}

restore() {
    DUMP="$1"
    INSTANCE=`docker ps | grep <%= instance %>_php | awk  '{print $1}'`
    if [ x"$INSTANCE" = x"" ]; then
        echo "Error! Cannot find php-<%= instance %> docker instance."
        exit 1
    fi
    cd ..
    if [ ! -f $DUMP ]; then
        echo "Cannot find or load sql file at $DUMP"
        exit 1
    fi
    echo
    echo "Restoring mysql dump:"
    echo "`du -sh $DUMP`"
    echo
    echo "Please wait, it can take some minutes..."
    echo
    docker exec -i $INSTANCE mysql -A -u drupal -pdrupal -h mariadb-<%= instance %> drupal < $DUMP
    echo "Done!"
}

backup() {
    if [ ! -d "../backups" ]; then
        mkdir "../backups"
    fi

    FILENAME="../backups/<%= instance %>-db-$(date +"%m_%d_%Y_%H_%m").sql"

    echo "Creating mysql dump $FILENAME ..."
    docker-compose exec --user=1000 php-<%= instance %> drush -r /var/www/html/web sql-dump > $FILENAME
    echo "Done! `du -sh $FILENAME`"
    cd ..
}

cli() {
    docker-compose exec --user=1000 php-<%= instance %> drush -r /var/www/html/web sql-cli
}

COMMAND=`echo $1 | sed 's/^[^=]*=//g'`

case "$COMMAND" in
    restore)
        DUMP=`echo $2 | sed 's/^[^=]*=//g'`
        restore $DUMP
        ;;
    backup)
        backup
        ;;
    cli)
        cli
        ;;
    *)
        echo "ERROR: unknown command \"$COMMAND\""
        usage
        exit 1
        ;;
esac
