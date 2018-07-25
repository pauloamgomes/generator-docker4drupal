# generator-docker4drupal
<https://npmjs.org/package/generator-docker4drupal>
<https://david-dm.org/pauloamgomes/generator-docker4drupal>

 
A basic generator for docker4drupal stack that permits easily the generation of
a docker4drupal (drupal 7 or 8) project.


Installation
------------

First, install [Yeoman](http://yeoman.io) and generator-docker4drupal using
[npm](https://www.npmjs.com/) (we assume you have pre-installed
[node.js](https://nodejs.org/)).

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ npm install -g yo
$ npm install -g generator-docker4drupal
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Usage
-----

Generate your new project:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ mkdir drupal8
$ cd drupal 8
$ yo docker4drupal
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

![Example](https://api.monosnap.com/rpc/file/download?id=IUI6SkXMnwtlQCYtUXThLz8bvOPSFR)

Generated project will contain the following structure:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.
+-- <sitename>.sh
+-- mysql.sh
+-- certs
|   +-- cert.pem
|   +-- key.pem
+-- docker
|   +-- docker-compose.yml
|   +-- docker-sync.yml
|   +-- examples
|       +-- development.services.yml
|       +-- settings.local.php
+-- docroot
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 

The certs folder provides pre-generated self signed certificates for using https
when accessing Drupal.

The docker/examples folder provides recommended settings for generated Drupal
project.

The docroot folder will be populated with vanilla Drupal from docker4drupal when
containers are initialised, if instead custom was used, its required to manual
add the Drupal files in docroot/web.

The bash script file <sitename>.sh can be used for various operations:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    USAGE: ./<sitename>.sh [OPTIONS]

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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When using vanilla option when running ./<sitename>.sh start for the first time,
Drupal will be automatically installed.
 

Getting To Know Yeoman
----------------------

-   Yeoman has a heart of gold.

-   Yeoman is a person with feelings and opinions, but is very easy to work
    with.

-   Yeoman can be too opinionated at times but is easily convinced not to be.

-   Feel free to [learn more about Yeoman](http://yeoman.io/).

 

License
-------

MIT © [Paulo Gomes]
