WiFiControl = Npm.require 'wifi-control'

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
    WiFiControl.scanForWiFi()
  resetWiFi: ->
    @unblock()
    WiFiControl.resetWiFi()
  connectToAP: ( _ap ) ->
    @unblock()
    WiFiControl.connectToAP _ap
