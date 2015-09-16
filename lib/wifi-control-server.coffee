#
# NPM Dependencies.
#
# For promised callbacks, we'll need Future.
@Future = Npm.require 'fibers/future'
# node-wifiscanner2 is a great NPM package for scanning WiFi APs.
@WiFiScanner = Npm.require 'node-wifiscanner2'
# On Windows, we need write .xml files to create network profiles :(
@fs = Npm.require 'fs'
# To execute commands in the host machine, we'll use child_process.exec!
@exec = Npm.require 'child_process'
  .exec

#
# WiFiControl Meteor Methods
#
Meteor.methods
  findInterface: ( forceInterface=null ) ->
    @unblock
    WiFiControl.findInterface forceInterface
  scanForWiFi: ->
    @unblock
    WiFiControl.scanForWiFi()
  resetWiFi: ->
    @unblock
    WiFiControl.resetWiFi()
  connectToAP: ( _ap ) ->
    @unblock()
    WiFiControl.connectToAP _ap
