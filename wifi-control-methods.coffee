Meteor.methods 
  findInterface: ( forceInterface ) ->
    WiFiControl.findInterface forceInterface
  connectToAP: ( _ap ) ->
    @unblock()
    WiFiControl.connectToAP _ap
  resetWiFi: ->
    WiFiControl.resetWiFi()
  scanAPs: ->
    WiFiControl.scanWiFi()
