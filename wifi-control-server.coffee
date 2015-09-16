#
# NPM Dependencies.
#
@Future = Npm.require 'fibers/future' # for promised callbacks!
@WiFiScanner = Npm.require 'node-wifiscanner2'  # for AP scanning functionality!
@fs = Npm.require 'fs' # Because Windows netsh requires .xml wireless profiles
@exec = Npm.require('child_process').exec # our main command line workhorse

#
# WiFiControl Meteor Methods
#
Meteor.methods
  WC_findInterface: ( forceInterface=null ) ->
    @unblock
    WiFiControl.findInterface forceInterface
  WC_scanForWiFi: ->
    @unblock
    WiFiControl.scanForWiFi()
  WC_resetWiFi: ->
    @unblock
    WiFiControl.resetWiFi()
  WC_connectToAP: ( _ap ) ->
    @unblock()
    WiFiControl.connectToAP _ap
