WiFiControl = Npm.require 'wifi-control'
@scanForWiFiSync = Meteor.wrapAsync WiFiControl.scanForWiFi

#
# WiFiControl Meteor Methods
#
Meteor.methods
  getIfaceState: ->
    @unblock()
    WiFiControl.getIfaceState()
  findInterface: ( forceInterface=null ) ->
    @unblock()
    WiFiControl.findInterface forceInterface
  scanForWiFi: ->
    @unblock()
    scanForWiFiSync()
  resetWiFi: ->
    @unblock()
    WiFiControl.resetWiFi()
  connectToAP: ( _ap ) ->
    @unblock()
    WiFiControl.connectToAP _ap
