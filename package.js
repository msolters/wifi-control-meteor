Package.describe({
  name: 'msolters:wifi-control',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: 'Connect or disconnect the host to wireless networks.  Useful for partially or fully offline apps, such as Electrified apps.',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Npm.depends({
  "node-wifiscanner2": "1.1.0",
  "future": "2.3.1"
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');
  api.use('coffeescript');
  api.addFiles('wifi-control.coffee', 'server');
  api.export('WiFiControl', 'server');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('msolters:wifi-control');
  api.addFiles('wifi-control-tests.js');
});
