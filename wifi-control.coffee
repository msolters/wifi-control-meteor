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
  DEBUG: false
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
    try
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
          findInterface = "ip link show | grep wlan | grep -i \"state UP\""
          @WiFiLog "Executing: #{findInterface}"
          exec findInterface, (error, stdout, stderr) =>
            if error?
              @WiFiLog stderr, true
              interfaceRequest.return {
                success: false
                msg: "Error: #{stderr}"
              }
            else
              _msg = "Success!"
              @WiFiLog _msg
              interfaceRequest.return {
                success: true
                msg: _msg
                interface: stdout.trim().split(": ")[1]
              }
        when "win32"
          @WiFiLog "Host machine is Windows."
          # On windows we are currently assuming wlan by default.
          findInterface = "echo wlan"
          @WiFiLog "Executing: #{findInterface}"
          exec findInterface, (error, stdout, stderr) =>
            if error?
              @WiFiLog stderr, true
              interfaceRequest.return {
                success: false
                msg: "Error: #{stderr}"
              }
            else
              _msg = "Success!"
              @WiFiLog _msg
              interfaceRequest.return {
                success: true
                msg: _msg
                interface: stdout.trim()
              }
        when "darwin"
          @WiFiLog "Host machine is MacOS."
          # On Mac, we get use the results of getting the route to
          # a public IP, and parse for interfaces.
          findInterface = "route get 10.10.10.10 | grep interface"
          @WiFiLog "Executing: #{findInterface}"
          exec findInterface, (error, stdout, stderr) =>
            if error?
              @WiFiLog stderr, true
              interfaceRequest.return {
                success: false
                msg: "Error: #{stderr}"
              }
            else
              _msg = "Success!"
              @WiFiLog _msg
              interfaceRequest.return {
                success: true
                msg: _msg
                interface: stdout.trim().split(": ")[1]
              }
        else
          @WiFiLog "Unrecognized operating system.  No known method for acquiring wireless interface."
          interfaceRequest.return {
            success: false
            msg: "No valid wireless interface could be located."
            interface: null
          }
      interfaceResult = interfaceRequest.wait()
      @IFACE = interfaceResult.interface
      return interfaceResult
    catch error
      _msg = "Encountered an error while searching for wireless interface: #{error}"
      @WiFiLog _msg, true
      return {
        success: false
        msg: _msg
      }
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
      @WiFiLog "Scanning for nearby WiFi Access Points..."
      scanRequest = new Future()
      WiFiScanner.scan (error, data) =>
        if error
          @WiFiLog "Error: #{error}", true
          scanRequest.return {
            success: false
            msg: "We encountered an error while scanning for WiFi APs: #{error}"
          }
        else
          _msg = "Nearby WiFi APs successfully scanned (#{data.length} found)."
          @WiFiLog _msg
          scanRequest.return {
            success: true
            networks: data
            msg: _msg
          }
      scanResults = scanRequest.wait()
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
    unless @IFACE?
      @WiFiLog "You cannot connect to a WiFi network without a valid wireless interface.", true
      return
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
        @WiFiLog "Generating win32 wireless profile..."
        #
        # (1) Convert SSID to Hex
        #
        ssid_hex = ""
        for i in [0..ssid.length-1]
          ssid_hex += ssid.charCodeAt(i).toString(16)
        #
        # (2) Generate XML content for the provided parameters.
        #
        xmlContent = "<?xml version=\"1.0\"?>
                      <WLANProfile xmlns=\"http://www.microsoft.com/networking/WLAN/profile/v1\">
                        <name>#{ssid}</name>
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
        #
        # (3) Write to XML file; wait until done.
        #
        xmlWriteRequest = new Future()
        fs.writeFile "#{ssid}.xml", xmlContent, (err) ->
          if err?
            @WiFiLog err, true
            xmlWriteRequest.return false
          else
            xmlWriteRequest.return true
        if !xmlWriteRequest.wait()
          return {
            success: false
            msg: "Encountered an error connecting to AP:"
          }
        #
        # (4) Load new XML profile, and connect to SSID.
        #
        COMMANDS =
          loadProfile: "netsh #{@IFACE} add profile filename=\"#{ssid}.xml\""
          connect: "netsh #{@IFACE} connect ssid=\"#{ssid}\" name=\"#{ssid}\""
        connectToPhotonChain = [ "loadProfile", "connect" ]
      when "darwin" # i.e., MacOS
        COMMANDS =
          connect: "networksetup -setairportnetwork #{@IFACE} \"#{ssid}\""
        connectToPhotonChain = [ "connect" ]

    for com in connectToPhotonChain
      commandRequest = new Future()
      @WiFiLog "Executing:\t#{COMMANDS[com]}"
      exec COMMANDS[com], (error, stdout, stderr) =>
        if error?
          @WiFiLog stderr, true
          commandRequest.return {
            success: false
            msg: "Error: #{stderr}"
          }
        else
          _msg = "Success!"
          @WiFiLog _msg
          commandRequest.return {
            success: true
            msg: _msg
          }
      commandResult = commandRequest.wait()
      return commandResult unless commandResult.success
    return {
      success: true
      msg: "Successfully connected to #{ssid}!"
    }
  #
  # resetWiFi:    Attempt to return the host machine's wireless to whatever
  #               network it connects to by default.
  #
  resetWiFi: ->
    #
    # (1) Choose commands based on OS.
    #
    switch process.platform
      when "linux"
        # With Linux, we just restart the network-manager, which will
        # immediately force its own preferences and defaults.
        COMMANDS =
          startNM: "sudo service network-manager restart"
        resetWiFiChain = [ "startNM" ]
      when "win32"
        # In Windows, we are just disconnecting from the current network.
        # This typically causes the wireless to then re-connect to its first
        # preference.
        COMMANDS =
          disconnect: "netsh #{@IFACE} disconnect"#"netsh #{IFACE} connect ssid=YOURSSID name=PROFILENAME"
        resetWiFiChain = [ "disconnect" ]
      when "darwin" # i.e., MacOS
        # In MacOS, we are going to turn the wireless off and then on again.
        # (lol)
        COMMANDS =
          enableAirport: "networksetup -setairportpower #{@IFACE} on"
          disableAirport: "networksetup -setairportpower #{@IFACE} off"
        resetWiFiChain = [ "disableAirport", "enableAirport" ]
    #
    # (2) Execute each command.
    #
    for com in resetWiFiChain
      commandRequest = new Future()
      @WiFiLog "Executing:\t#{COMMANDS[com]}"
      exec COMMANDS[com], (error, stdout, stderr) =>
        if error?
          @WiFiLog stderr, true
          commandRequest.return {
            success: false
            msg: "Error: #{error}"
          }
        else
          _msg = "Success!"
          @WiFiLog _msg
          commandRequest.return {
            success: true
            msg: _msg
          }
      commandResult = commandRequest.wait()
      return commandResult unless commandResult
    return {
      success: true
      msg: "Successfully reset WiFi!"
    }

#   On boot, before the user does anything, we need
#   to find a valid wireless interface.
WiFiControl.findInterface()
