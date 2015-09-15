# WiFi-Control

A Meteor Smart Package that allows for scanning for local WiFi access points, as well as connecting/disconnecting to networks.  Since this requires access to the local network card(s), it will only work on the server.  This is great for local or (partially) offline apps.  Maybe you have a SoftAP-based IoT toy, and you just need to make a thin downloadeable "setup" client?

This package uses the [node-wifiscanner2 NPM package](https://www.npmjs.com/package/node-wifiscanner2) by Spark for the heavy lifting where AP scanning is concerned.

# Methods
All methods are presently synchronous.  This was a decision made that reflects the underlying purpose of this package -- sequential SoftAP setup wizards.

## Scan for Networks

```js
  var results = WiFiControl.scan();
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
