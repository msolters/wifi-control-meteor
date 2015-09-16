# WiFi-Control

A Meteor Smart Package that allows for scanning for local WiFi access points, as well as connecting/disconnecting to networks.  Since this requires access to the local network card(s), it will only work on the server.  This is great for local or (partially) offline apps.  Maybe you have a SoftAP-based IoT toy, and you just need to make a thin downloadeable "setup" client?

```sh
  meteor add msolters:wifi-control
```

## Example:

(Server)
```js
  Meteor.startup({
    //  Initialize wifi-control package
    WiFiControl.init();
  });
```

(Client)
```js
  Meteor.call( "scanForWiFi", function(err, response) {
    console.log( response );
  });
```

Example Output:
```json
{
  "success":  true,
  "networks":
    [ { "mac": "AA:BB:CC:DD:EE:FF",
        "channel": "1",
        "signal_level": "-43",
        "ssid": "Home 2.4Ghz" } ],
  "msg":"Nearby WiFi APs successfully scanned (1 found)."
}
```


# Methods
WiFiControl exports the `WiFiControl` object to your server-side code, giving you access to all the below methods needed to programmatically scan or (dis)connect to and from wireless access points.  However, it also comes right out of the box with some helpful Meteor methods that wrap these methods, making it easy to call them directly from your client code.

You may find it more convenient roll your own Meteor methods if you need to extensive transformations, such as filtering through WiFi scan results to return only networks that match a certain SSID prefix rule.

**A Note About Synchronicity** (*Synchronicity!*)

All `WiFiControl` methods are synchronous.  Calls to them will block.  This is a decision made that reflects the fact that low-level system operations such as starting and stopping network interfaces should not be happening simultaneously.  *However*, the provided Meteor methods implement `this.unblock()`, which prevents other server-side code (such as unrelated Meteor methods) from grinding to a halt while the operating system is handling hardware issues.

Therefore, it is recommended that if you roll your own Meteor methods, you add `this.unblock()` to prevent this problem in your own code.  Otherwise, no subsequent Meteor methods will be processed until the `WiFiControl` method returns to the first Meteor method that called it.

---

##  Initialize
(Server only)
```
  WiFiControl.init();
```

Before `WiFiControl` can scan or connect/disconnect using the host machine's wireless interface, it must know what that wireless interface is!

To initialize the network interface and simultaneously pass in any custom settings, simply call `WiFiControl.init( settings )` on the server at startup.  `settings` is an optional parameter -- see `WiFiControl.configure( settings )` below.

To instruct the `WiFiControl` module to locate a wireless interface programmatically, or to manually force a network interface, see the `WiFiControl.findInterface( interface )` command.

##  Configure
You can change `WiFiControl` settings at any time using this method.

Possible `WiFiControl` settings are as follows:

(Server only)
```js
  var settings = {
    debug: true | false,
    iface: 'wlan0'
  };
  WiFiControl.configure( settings );
  // also WiFiControl.init( settings );
```

*  `debug`:  When `debug: true`,  will turn on verbose output to the server console.  When `debug: false` (default), only errors will be printed to the server console.
*  `iface` can be used to manually specify a network interface to use, instead of relying on `WiFiControl.findInterface()` to automatically find it.  This could be useful if for any reason `WiFiControl.findInterface()` is not working, or you have multiple network cards.

## Scan for Networks
This package uses the [node-wifiscanner2 NPM package](https://www.npmjs.com/package/node-wifiscanner2) by Spark for the heavy lifting where AP scanning is concerned.

Direct call:
(Server only)
```js
  var results = WiFiControl.scan();
```

Meteor method:
(Server or Client)
```js
  Meteor.call( "scanForWiFi", function(err, response) {
    console.log( response );
  });
```

Example output:
```json
{
  "success":  true,
  "networks":
    [ { "mac": "AA:BB:CC:DD:EE:FF",
        "channel": "1",
        "signal_level": "-43",
        "ssid": "Home 2.4Ghz" } ],
  "msg":"Nearby WiFi APs successfully scanned (1 found)."
}
```

## Connect To WiFi Network
The `WiFiControl.connectToAP( _ap )` command takes a wireless access point as an object and attempts to direct the host machine's wireless interface to connect to it.

Direct call:
(Server only)
```js
  var _ap = {
    ssid: "Home 2.4Ghz",
    security: false,
    password: ""
  };
  var results = WiFiControl.connectToAP( _ap );
```

Meteor method:
(Server or Client)
```js
  var _ap = {
    ssid: "Home 2.4Ghz",
    security: false,
    password: ""
  };
  Meteor.call( "connectToAP", _ap, function(err, response) {
    console.log( response );
  });
```

## Find Wireless Interface
It should not be necessary to use this method often.  Unless your wireless cards are frequently changing or being turned on or off, wireless interfaces are not expected to change a great deal.

This method, when called with no argument, will attempt to automatically locate a valid wireless interface on the host machine.

When supplied a string argument `interface`, that value will be used as the host machine's intended wireless interface.  Typical values for various operating systems are:

OS | Typical Values
---|---
Linux | wlan0, wlan1, ...
Windows | wlan
MacOS | en0, en1, ...

Direct call:
(Server only)
```js
  var results = WiFiControl.findInterface();
```

Meteor method:
(Server or Client)
```js
  var _ap = {
    ssid: "Home 2.4Ghz",
    security: false,
    password: ""
  };
  Meteor.call( "findInterface", "wlan2", function(err, response) {
    console.log( response );
  });
```

Output:
```json
{
  "success":  true,
  "msg":  "Automatically located wireless interface wlan2.",
  "interface":  "wlan2"
}
```

# Some Notes
Linux won't let you mess with your wireless without authenticating as root.  Therefore, you may find some or all WiFi features do not work unless you launch your app with `sudo meteor`.  Alternatively, you may find the server will prompt you for a password in the same console where you launched `meteor`, and will hang there until you provide it.
