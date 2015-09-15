#
# NPM Dependencies.
#
@Future = Npm.require 'fibers/future' # for promised callbacks!
@WiFiScanner = Npm.require 'node-wifiscanner2'  # for AP scanning functionality!
@exec = Npm.require('child_process').exec # our main command line workhorse
@fs = Npm.require('fs') # Because Windows netsh requires .xml wireless profiles


#
# Define WiFiControl object and methods.
#
WiFiControl =
  IFACE: null
  DEBUG: true
  #
  #
  # WiFiLog:        Helper method for debugging and throwing
  #                 errors.
  #
  WiFiLog: (msg, error=false) ->
    if error
      console.error "WiFiControl: #{msg}"
    else
      console.log "WiFiControl: #{msg}" if @DEBUG
  #
  # findInterface:  Search host machine to find an active
  #                 WiFi card interface.
  #
  findInterface: ->
    #
    # (1) First, we find the wireless card interface on the host.
    #
    @WiFiLog "Determining system wireless interface..."
    interfaceRequest = new Future
    switch process.platform
      when "linux"
        @WiFiLog "Host machine is Linux."
        # On linux, we use the results of `ip link show` and parse for
        # active `wlan*` interfaces.
        getIFACE = "ip link show | grep wlan | grep -i \"state UP\""
        exec getIFACE, (error, stdout, stderr) =>
          interfaceRequest.return stdout.trim().split(": ")[1]
      when "win32"
        @WiFiLog "Host machine is Windows."
        # On windows // we are currently assuming wlan by default.
        interfaceRequest.return "wlan" # default
      when "darwin"
        @WiFiLog "Host machine is MacOS."
        # On Mac, we get use the results of getting the route to
        # a public IP, and parse for interfaces.
        getIFACE = "route get 10.10.10.10 | grep interface"
        exec getIFACE, (error, stdout, stderr) =>
          interfaceRequest.return stdout.trim().split(": ")[1]
      else
        interfaceRequest.return null
    interfaceRequest.wait()
    #
    # (2) Did we find something?
    #
    if !interfaceRequest.value?
      @WiFiLog "wifi-control was not able to find a wireless card interface on the host machine.", true
    else
      @IFACE = interfaceRequest.value
      @WiFiLog "Host machine is using wireless interface #{@IFACE}"
  #
  # scanWiFi:   Return a list of nearby WiFi access points by using the
  #             host machine's wireless interface.  For this, we are using
  #             the NPM package node-wifiscanner2 by Particle (aka Spark).
  #
  scanWiFi: ->
    unless @IFACE?
      @WiFiLog "You cannot scan for nearby WiFi networks without a valid wireless interface.", true
      return
    try
      fut = new Future()
      WiFiScanner.scan (err, data) ->
        if err
          fut.return {
            success: false
            msg: "We encountered an error while scanning for WiFi APs: #{error}"
          }
        else
          fut.return {
            success: true
            networks: data
            msg: "Nearby WiFi APs successfully scanned (#{data.length} found)."
          }
      fut.wait()
    catch error
      return {
        success: false
        msg: "We encountered an error while scanning for WiFi APs: #{error}"
      }
  #
  # connectToAP:    Direct the host machine to connect to a specific WiFi AP
  #                 using the specified parameters.
  #                 security and pw are optional parameters; calling with
  #                 only an ssid connects to an open network.
  #
  connectToAP: (ssid, security=false, pw=false) ->
    switch process.platform
      when "linux"
        #
        # With Linux, we can use ifconfig, iwconfig & dhclient to do most
        # of our heavy lifting.
        #
        # NOTE: The most important thing with Linux is that to automate WiFi
        #       control, we must turn off the network-manager service while
        #       we do so.
        #
        COMMANDS =
          stopNM: "sudo service network-manager stop"
          enableIFACE: "sudo ifconfig #{@IFACE} up"
          connect: "sudo iwconfig #{@IFACE} essid \"#{ssid}\""
          getIP: "sudo dhclient #{@IFACE}"
          startNM: "sudo service network-manager start"
        connectToPhotonChain = [ "stopNM", "enableIFACE", "connect", "getIP"  ]
      when "win32"
        #
        # Windows is a special child.  While the netsh command provides us
        # quite a bit of functionality, the real kicker is that to connect
        # to a given network using it, we must first have a so-called wireless
        # profile for that network in the machine.
        # This can be done ONLY through the GUI, or by loading an XML file which
        # must already contain the SSID information in plaintext and as HEX.
        # Once we create this XML file, we will add the profile inside, and then
        # connect to it all using the netsh command.
        #
        ssid_hex = ""
        for i in [0..ssid.length-1]
          ssid_hex += ssid.charCodeAt(i).toString(16)
        ssid.charCodeAt(i).toString(16)
        xmlContent = "<?xml version=\"1.0\"?>
                      <WLANProfile xmlns=\"http://www.microsoft.com/networking/WLAN/profile/v1\">
                        <name>Photon-SoftAP</name>
                        <SSIDConfig>
                          <SSID>
                            <hex>#{ssid_hex}</hex>
                            <name>#{ssid}</name>
                          </SSID>
                        </SSIDConfig>
                        <connectionType>ESS</connectionType>
                        <connectionMode>manual</connectionMode>
                        <MSM>
                          <security>
                            <authEncryption>
                              <authentication>open</authentication>
                              <encryption>none</encryption>
                              <useOneX>false</useOneX>
                            </authEncryption>
                          </security>
                        </MSM>
                      </WLANProfile>"
        xmlWriteRequest = new Future()
        fs.writeFile "Photon-SoftAP.xml", xmlContent, (err) ->
          if err?
            console.error err
            fut.return false
          else
            fut.return true
        if !fut.wait()
          return {
            success: false
            msg: "Encountered an error connecting to Photon: #{error}"
          }
        COMMANDS =
          loadProfile: "netsh #{@IFACE} add profile filename=\"Photon-SoftAP.xml\""
          connect: "netsh #{@IFACE} connect ssid=\"#{ssid}\" name=\"Photon-SoftAP\""
        connectToPhotonChain = [ "loadProfile", "connect" ]
      when "darwin" # i.e., MacOS
        COMMANDS =
          connect: "networksetup -setairportnetwork #{@IFACE} \"#{ssid}\""
        connectToPhotonChain = [ "connect" ]

    for com in connectToPhotonChain
      fut = new Future()
      console.log "Executing #{COMMANDS[com]}"
      child = exec COMMANDS[com], (error, stdout, stderr) ->
        console.log "stdout: #{stdout}"
        console.log "stderr: #{stderr}"
        if error?
          console.log "exec error: #{error}"
          fut.return {
            success: false
            msg: "Encountered an error connecting to Photon: #{error}"
          }
        else
          fut.return {
            success: true
            msg: "Successfully ran #{COMMANDS[com]}"
          }
      result = fut.wait()
      if !result.success
        return result
      else
        console.log result.msg
    return {
      success: true
      msg: "Successfully connected to Photon!"
    }
  resetWiFi: =>
    #
    # (1) Determine operating system
    #
    switch @PLATFORM
      when "linux"
        COMMANDS =
          startNM: "sudo service network-manager start"
        resetWiFiChain = [ "startNM" ]
      when "win32"
        COMMANDS =
          disconnect: "netsh #{@IFACE} disconnect"#"netsh #{IFACE} connect ssid=YOURSSID name=PROFILENAME"
        resetWiFiChain = [ "disconnect" ]
      when "darwin" # i.e., MacOS
        COMMANDS =
          enableAirport: "networksetup -setairportpower #{@IFACE} on"
          disableAirport: "networksetup -setairportpower #{@IFACE} off"
        resetWiFiChain = [ "disableAirport", "enableAirport" ]

    for com in resetWiFiChain
      fut = new Future()
      child = exec COMMANDS[com], (error, stdout, stderr) ->
        #console.log "stdout: #{stdout}"
        #console.log "stderr: #{stderr}"
        if error?
          console.log "exec error: #{error}"
          fut.return {
            success: false
            msg: "Encountered an error resetting WiFi: #{error}"
          }
        else
          fut.return {
            success: true
            msg: "Successfully returned to home WiFi!"
          }
      if !fut.wait().success
        return fut.wait()
    return {
      success: true
      msg: "Successfully returned to home WiFi!"
    }

#   Try to find a valid WiFi interface on boot.
WiFiControl.findInterface()
