Package.describe({
  name: 'msolters:wifi-control',
  version: '0.1.3',
  // Brief, one-line summary of the package.
  summary: 'Scan for, connect to, or disconnect from WiFi networks.',
  // URL to the Git repository containing the source code for this package.
  git: 'https://github.com/msolters/wifi-control-meteor',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Npm.depends({
  "wifi-control": "0.1.3"
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');
  api.use('coffeescript');
  api.addFiles( ['wifi-control.coffee'], 'server');
  api.export('WiFiControl', 'server');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('msolters:wifi-control');
  api.addFiles('wifi-control-tests.js');
});
