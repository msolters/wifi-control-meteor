# WiFi-Control

```sh
  meteor add msolters:wifi-control
```

A Meteor Smart Package that allows for scanning for local WiFi access points, as well as connecting/disconnecting to networks.  Since this requires access to the local network card(s), it will only work on the server.  This is great for local or (partially) offline apps.  Maybe you have a SoftAP-based IoT toy, and you just need to make a thin downloadeable "setup" client?

This package is a wrapper of the node module by the [same name](https://www.npmjs.com/package/wifi-control).  For a complete breakdown of `WiFiControl` syntax, refer to that documentation.  Keep in mind that the `WiFiControl` object is only available on the server!

## Example:

(Server)
```js
  Meteor.startup({
    //  Initialize wifi-control package with defaults
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

All native `WiFiControl` methods are synchronous.  Calls to them will block.  This is a decision made that reflects the fact that low-level system operations such as starting and stopping network interfaces should not be happening simultaneously.  Plus, there's lots of situations where you need to wait -- you can't communicate over a network, for instance, until you're totally sure you've fully associated with the router.  *However*, the provided Meteor methods implement `this.unblock()`, which prevents other server-side code (such as unrelated Meteor methods) from grinding to a halt while the operating system is handling these hardware issues.

Therefore, it is recommended that if you roll your own Meteor methods on the server that use `WiFiControl` methods, you add `this.unblock()` to prevent this problem in your own code.  Otherwise, no subsequent Meteor methods will be processed until the `WiFiControl` method returns to the first Meteor method that called it.

---

##  Initialize
Server only
```
  WiFiControl.init( settings );
```

Before `WiFiControl` can scan or connect/disconnect using the host machine's wireless interface, it must know what that wireless interface is!

To initialize the network interface and simultaneously pass in any custom settings, simply call `WiFiControl.init( settings )` on the server at startup.  `settings` is an optional parameter -- see [`WiFiControl.configure( settings )`](https://github.com/msolters/wifi-control#configure) below.

To instruct the `WiFiControl` module to locate a wireless interface programmatically, or to manually force a network interface, see the `WiFiControl.findInterface( interface )` command.

##  Configure
Server only
```js
  WiFiControl.configure( settings );
```
You can change the `WiFiControl` settings at any time using this method.  Possible `WiFiControl` settings are illustrated in the following example:

```js
  // Server only
  var settings = {
    debug: true | false,
    iface: 'wlan0'
  };
  WiFiControl.configure( settings );
  // also WiFiControl.init( settings );
```

**Settings Object**
key | Explanation
---|---
`debug` | (optional, bool) When `debug: true`,  will turn on verbose output to the server console.  When `debug: false` (default), only errors will be printed to the server console.
`iface` | (optional, string) can be used to manually specify a network interface to use, instead of relying on `WiFiControl.findInterface()` to automatically find it.  This could be useful if for any reason `WiFiControl.findInterface()` is not working, or you have multiple network cards.

## Scan for Networks
This package uses the [node-wifiscanner2 NPM package](https://www.npmjs.com/package/node-wifiscanner2) by Spark for the heavy lifting where AP scanning is concerned.  However, on Linux, we use a custom approach that leverages `nmcli` which bypasses the `sudo` requirement of `iwlist` and permits us to more readily scan local WiFi networks.

Server only
```js
  var results = WiFiControl.scan();
```

Server or Client
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
```js
  var results = WiFiControl.connectToAP( _ap );
```
The `WiFiControl.connectToAP( _ap )` command takes a wireless access point as an object and attempts to direct the host machine's wireless interface to connect to it.

Server only
```js
  var _ap = {
    ssid: "Home 2.4Ghz",
    password: "mypassword"
  };
  var results = WiFiControl.connectToAP( _ap );
```

Server or Client
```js
  var _ap = {
    ssid: "Home 2.4Ghz",
    password: "mypassword"
  };
  Meteor.call( "connectToAP", _ap, function(err, response) {
    console.log( response );
  });
```

This method will not return until the host machine has either connected to the requested AP, or failed to do so and returns an error explaining why.  Depending on your physical topology, this can up to a minute to resolve.

> Note:  Currently, Windows can only connect to open networks.  This is due to the encryption-specific XML formatting of Windows wireless profiles and we are currently working on it.


## Reset Wireless Interface
Server only
```js
  WiFiControl.resetWiFi();
```

After connecting or disconnecting to various APs programmatically (which may or may not succeed) it is useful to have a way to reset the network interface to system defaults.

This method attempts to do that, either by disconnecting the interface or restarting the system manager, if it exists.  It will report either success or failure in the return message.

Server or Client
```js
  Meteor.call( "resetWiFi", function(err, response) {
    console.log( response );
  });
```


## Get Connection State
```js
  var ifaceState = WiFiControl.getIfaceState();
```

This method will tell you whether or not the wireless interface is connected to an access point, and if so, what SSID.  This method is used internally, for example, when `WiFiControl.connectToAP( _ap )` is called, to make sure that the interface either successfully connects or unsuccessfully does something else before returning.

Server or Client
```js
  Meteor.call( "getIfaceState", function(err, response) {
    console.log( response );
  });
```

Example output:
```js
ifaceState = {
  "success": true
  "msg": "Successfully acquired state of network interface wlan0."
  "ssid": "Home 2.4Ghz"
  "state": "connected"
}
```

## Find Wireless Interface
Server only
```js
  var results = WiFiControl.findInterface();
```
It should not be necessary to use this method often.  Unless your wireless cards are frequently changing or being turned on or off, wireless interfaces are not expected to change a great deal.

This method, when called with no argument, will attempt to automatically locate a valid wireless interface on the host machine.

When supplied a string argument `interface`, that value will be used as the host machine's intended wireless interface.  Typical values for various operating systems are:

OS | Typical Values
---|---
Linux | wlan0, wlan1, ...
Windows | wlan
MacOS | en0, en1, ...

**Automatic**
Server or Client
```js
  Meteor.call( "findInterface", function(err, response) {
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

**Manual**
Server or Client
```js
  Meteor.call( "findInterface", "wlan0", function(err, response) {
    console.log( response );
  });
```

Output:
```json
{
  "success":  true,
  "msg":  "Wireless interface manually set to wlan0.",
  "interface":  "wlan0"
}
```

# Notes
This library has been tested on Ubuntu & MacOS with no problems.

Of the 3 OSs provided here, Windows is currently the least tested.  Expect bugs with:

*  Connecting to secure APs in win32
*  Resetting network interfaces in win32


## Change Log
### v0.1.4
9/23/2015
*  `WiFiControl.resetWiFi()` blocks until wireless interface reports it has reset or returns an error.
*  `WiFiControl.getIfaceState()` now returns information about if the wireless interface is powered or not.

### v0.1.3
9/19/2015
*  `WiFiControl.getIfaceState()`
*  `WiFiControl.connectToAP( ap )` now waits on `WiFiControl.getIfaceState()` to ensure network interface either succeeds or fails in connection attempt before returning a result.  This definitely works on MacOS and Linux.

### v0.1.2
9/18/2015

*  `WiFiControl.init( settings )` and `WiFiControl.configure( settings )`
*  `WiFiControl.connectToAP( ap )`, does not wait for connection to settle, no secure AP for win32 yet.
*  `WiFiControl.findInterface( iface )`
*  `WiFiControl.scan()`
