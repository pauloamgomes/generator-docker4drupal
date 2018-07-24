'use strict';
const Generator = require('yeoman-generator');
const chalk = require('chalk');
const yosay = require('yosay');
var _ = require('lodash');
var mkdirp = require('mkdirp');
var sleep = require('sleep');

const phpImages = {
  vanilla: [
    {value: '8-7.2-4.5.2', name: 'Drupal 8 - PHP 7.2'},
    {value: '8-7.1-4.5.2', name: 'Drupal 8 - PHP 7.1'},
    {value: '7-7.2-4.5.2', name: 'Drupal 7 - PHP 7.2'},
    {value: '7-7.1-4.5.2', name: 'Drupal 7 - PHP 7.1'},
    {value: '7-5.6-4.5.2', name: 'Drupal 7 - PHP 5.6'}
  ],
  custom: [
    {value: '7.2-dev-4.5.2', name: 'PHP 7.2 (Linux)'},
    {value: '7.1-dev-4.5.2', name: 'PHP 7.1 (Linux)'},
    {value: '5.6-dev-4.5.2', name: 'PHP 5.6 (Linux)'},
    {value: '7.2-dev-macos-4.5.2', name: 'PHP 7.2 (macOS)'},
    {value: '7.1-dev-macos-4.5.2', name: 'PHP 7.1 (macOS)'},
    {value: '5.6-dev-macos-4.5.2', name: 'PHP 5.6 (macOS)'}
  ]
};

const nginxImages = {
  D8: '8-1.15-4.2.0',
  D7: '7-1.15-4.2.0'
};

module.exports = class extends Generator {
  prompting() {
    // Have Yeoman greet the user.
    this.log('\x1Bc');
    this.log(chalk.cyan('                                           '));
    this.log(chalk.cyan('                    `/.                    '));
    this.log(chalk.cyan('                    /yys+-                 '));
    this.log(chalk.cyan('                 `:syyyyyys/.              '));
    this.log(chalk.cyan('              `:oyyyyyyyyyyyys/`           '));
    this.log(chalk.cyan('            .+yyyyyyyyyyyyyyyyyy+.         '));
    this.log(chalk.cyan('          `+yyyyyyyyyyyyyyyyyyyyyy/        '));
    this.log(chalk.cyan('         `oyyyyyyyyyyyyyyyyyyyyyyyyo`      '));
    this.log(chalk.cyan('         +yyyyyyyyyyyyyyyyyyyyyyyyyy+      '));
    this.log(chalk.cyan('        .yyyyyyyyyyyyyyyyyyyyyyyyyyyy.     '));
    this.log(chalk.cyan('        :yyyyyyyys+//+oyyyyyyyyysosyy:     '));
    this.log(chalk.cyan('        -yyyyyys.       .+yyyo:`   .y-     '));
    this.log(chalk.cyan('         syyyyy-          `/.       o      '));
    this.log(chalk.cyan('         .yyyyy+        `:sy/      /.      '));
    this.log(chalk.cyan('          .syyyys:...-/oyo/:ss/--/o.       '));
    this.log(chalk.cyan('           `/yyyyyyyyy/osyyyosyyy/`        '));
    this.log(chalk.cyan('             `:oyyyyyys/:://oyo:`          '));
    this.log(chalk.cyan('                `-:+oossoo+:-`             '));
    this.log(chalk.cyan('                                           '));

    this.log(yosay(
      'Welcome to the ' + chalk.yellow('docker4drupal') + ' generator!'
    ));

    const prompts = [{
      type: 'list',
      name: 'genType',
      message: 'docker4drupal codebase? ',
      choices: [
        {
          value: 'vanilla',
          name: 'Downloads Drupal using docker4drupal defaults'
        },
        {
          value: 'custom',
          name: 'Run Drupal from an existing codebase'
        }
      ]
    },
    {
      type: 'list',
      name: 'phpImage',
      message: 'Docker PHP Image? ',
      choices: phpImages.vanilla,
      when: function (answers) {
        return answers.genType === 'vanilla';
      }
    },
    {
      type: 'list',
      name: 'phpImage',
      message: 'Docker PHP Image? ',
      choices: phpImages.custom,
      when: function (answers) {
        return answers.genType === 'custom';
      }
    },
    {
      type: 'list',
      name: 'drupalVersion',
      message: 'Drupal Version? ',
      choices: [
        {value: 'D8', name: 'Drupal 8'},
        {value: 'D7', name: 'Drupal 7'}
      ],
      when: function (answers) {
        return answers.genType === 'custom';
      }
    },
    {
      name: 'siteName',
      message: 'What is your drupal site name? ',
      default: _.startCase(this.appname)
    },
    {
      name: 'siteMachineName',
      message: 'What is your drupal site machine name? EX: d8',
      default: function (answers) {
        // Default to snake case theme name
        return _.snakeCase(answers.siteName);
      }
    },
    {
      name: 'domain',
      message: 'What is your drupal site domain? Ex: drupal.docker.localhost',
      default: function (answers) {
        return `${answers.siteMachineName}.docker.localhost`;
      }
    },
    {
      name: 'httpPort',
      message: 'http port? Ex: 80, 8081, 8082',
      default: '80'
    },
    {
      name: 'httpsPort',
      message: 'https port? Ex: 443, 8443, 9443',
      default: '443'
    },
    {
      type: 'list',
      name: 'solr',
      message: 'Enable Apache SOLR? ',
      choices: [
        {
          value: '#',
          name: 'No'
        },
        {
          value: '',
          name: 'Yes'
        }
      ]
    },
    {
      type: 'list',
      name: 'redis',
      message: 'Enable Redis? ',
      choices: [
        {
          value: '#',
          name: 'No'
        },
        {
          value: '',
          name: 'Yes'
        }
      ]
    },
    {
      type: 'list',
      name: 'memcached',
      message: 'Enable memcached? ',
      choices: [
        {
          value: '#',
          name: 'No'
        },
        {
          value: '',
          name: 'Yes'
        }
      ]
    },
    {
      type: 'list',
      name: 'dockerSync',
      message: 'Use docker-sync?',
      choices: [
        {value: '', name: 'Yes'},
        {value: '#', name: 'No'}
      ]
    }];

    return this.prompt(prompts).then(props => {
      this.props = props;
    });
  }

  writing() {
    var drupalVersion = 'D8';
    var drupalTag = '';
    var phpTagPrefix = 'drupal';
    if (this.props.genType === 'vanilla') {
      drupalVersion = 'D' + this.props.phpImage.match(/^([7-8])-/)[1];
    } else {
      drupalVersion = this.props.drupalVersion;
      phpTagPrefix = 'drupal-php';
    }

    var syncVolume = '../docroot';
    var syncCertsVolume = '../certs';
    if (this.props.dockerSync == '') {
      syncVolume = 'sync-' + this.props.siteMachineName;
      syncCertsVolume = 'sync-certs-' + this.props.siteMachineName;
    }

    this.fs.copyTpl(
      this.templatePath('.env'),
      this.destinationPath('docker/.env'),
      {
        domain: this.props.domain,
        instance: this.props.siteMachineName,
        drupalTag: this.props.phpImage,
        phpTag: this.props.phpImage,
        nginxTag: nginxImages[drupalVersion]
      }
    );

    this.fs.copyTpl(
      this.templatePath('docker-compose.yml'),
      this.destinationPath('docker/docker-compose.yml'),
      {
        domain: this.props.domain,
        instance: this.props.siteMachineName,
        phpImage: this.props.phpImage,
        phpTagPrefix: phpTagPrefix,
        nginxImage: nginxImages[drupalVersion],
        httpPort: this.props.httpPort,
        httpsPort: this.props.httpsPort,
        solr: this.props.solr,
        redis: this.props.redis,
        memcached: this.props.memcached,
        syncVolume: syncVolume,
        syncCertsVolume: syncCertsVolume,
        dockerSync: this.props.dockerSync
      }
    );
    this.fs.copyTpl(
      this.templatePath('docker-sync.yml'),
      this.destinationPath('docker/docker-sync.yml'),
      {
        instance: this.props.siteMachineName
      }
    );
    this.fs.copyTpl(
      this.templatePath('docker4drupal.sh'),
      this.destinationPath(this.props.siteMachineName + '.sh'),
      {
        instance: this.props.siteMachineName,
        siteName: this.props.siteName,
        domain: this.props.domain,
        genType: this.props.genType,
        version: drupalVersion,
        dockerSync: this.props.dockerSync
      }
    );
    // Mysql helper script.
    this.fs.copyTpl(
      this.templatePath('mysql.sh'),
      this.destinationPath('docker/mysql.sh'),
      {
        instance: this.props.siteMachineName
      }
    );
    // Only for D8.
    if (drupalVersion === 'D8') {
      this.fs.copy(
        this.templatePath('D8/development.services.yml'),
        this.destinationPath('docker/examples/development.services.yml')
      );
      this.fs.copyTpl(
        this.templatePath('D8/settings.local.php'),
        this.destinationPath('docker/examples/settings.local.php'),
        {
          domain: this.props.domain,
          instance: this.props.siteMachineName
        }
      );
    }
    mkdirp('docroot');
    mkdirp('certs');
  }

  install() {
    this.spawnCommand('openssl', ['req', '-x509', '-nodes', '-days', '365', '-newkey', 'rsa:2048', '-subj', '/C=UK/ST=Drupal/L=Mars/O=Dis/CN=' + this.props.domain, '-keyout', 'certs/key.pem', '-out', 'certs/cert.pem']);
    sleep.sleep(5);
    this.log(chalk.green('\nDocker and Drupal related files generated.'));
    this.log(chalk.bold.yellow('Run ./' + this.props.siteMachineName + '.sh for list of available commands'));
  }
};
