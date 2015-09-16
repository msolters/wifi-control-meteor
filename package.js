Package.describe({
  name: 'msolters:wifi-control',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: 'Scan for, connect to, or disconnect from WiFi networks.  Useful for partially or fully offline apps, such as Electrified apps.',
  // URL to the Git repository containing the source code for this package.
  git: 'https://github.com/msolters/wifi-control',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Npm.depends({
  "node-wifiscanner2": "1.1.0"
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');
  api.use('coffeescript');
  api.addFiles( ['lib/wifi-control.coffee', 'lib/wifi-control-server.coffee'], 'server');
  api.export('WiFiControl', 'server');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('msolters:wifi-control');
  api.addFiles('wifi-control-tests.js');
});
