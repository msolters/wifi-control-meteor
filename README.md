# WiFi-Control

A Meteor Smart Package that allows for scanning for local WiFi access points, as well as connecting/disconnecting to networks.  Since this requires access to the local network card(s), it will only work on the server.  This is great for local or (partially) offline apps.  Maybe you have a SoftAP-based IoT toy, and you just need to make a thin downloadeable "setup" client?

This package uses the [node-wifiscanner2 NPM package](https://www.npmjs.com/package/node-wifiscanner2) by Spark for the heavy lifting where AP scanning is concerned.

### Example Use:
(On Server)

```js
  //  Initialize wifi-control package
  WiFiControl.init();

  //  Create Meteor methods to expose wifi-control functionality to the client.
  Meteor.methods({
    findInterface: function() {
      return( WiFiControl.findInterface() );
    },
    connectToAP: function( _ap ) {
      return( WiFiControl.connectToAP( _ap ) );
    },
    resetWiFi: function() {
      return( WiFiControl.resetWiFi() );
    },
    scanAPs: function() {
      return( WiFiControl.scanForWiFi() );
    }
  });
```

# Methods
All methods are presently synchronous.  This was a decision made that reflects the underlying purpose of this package -- sequential SoftAP setup wizards.

##  Initialize
The `WiFiControl.init()` method must be called before any other methods.  It accepts an optional object parameter, settings:

```js
var settings = {
  debug: true | false,
  iface: 'wlan0'
};
WiFiControl.init( settings );
```

*  `debug`, when `true`,  will turn on verbose output to the server console.
*  `iface` can be used to manually specify a network interface to use, instead of using `WiFiControl.findInterface()` to automatically find it.  This could be useful if, for some reason `WiFiControl.findInterface()` is not working, or you have multiple network cards.

## Scan for Networks

```js
  var results = WiFiControl.scan();
```

Example output:

```js
results = {
  success: true,
  networks:
    [ { mac: '2C:5D:93:0D:1B:68',
        channel: '11',
        signal_level: '-42',
        ssid: 'CIC' } ],
  msg: 'Nearby WiFi APs successfully scanned (1 found).'
}
```

## Connect To WiFi Network


```js
  var results = WiFiControl.connectToAP(ssid, security, password);
```

## Find Wireless Interface
It should not be necessary to use this method often.  It is called when the server boots up, and unless your wireless cards are frequently changing or being turned on or off, wireless interfaces are not expected to change that much.  The purpose of this app is to internally configure the `WiFiControl` tools to know what wireless interface your system has available.

```js
  var results = WiFiControl.findInterface();
```

# Some Notes
Linux won't let you mess with your wireless without authenticating as root.  Therefore, you may find some or all WiFi features do not work unless you launch your app with `sudo meteor`.
