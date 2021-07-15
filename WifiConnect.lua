function checkConnection(cb) 
  if ( wifiTrys > NUMWIFITRYS ) then
    print("Sorry. Not able to connect")
  else
    ipAddr = wifi.sta.getip()
    if ( ( ipAddr == nil ) or ( ipAddr == "0.0.0.0" ) )then
     -- Reset alarm again
       print("no connection; "..wifiTrys.." tries")
      wifiTimeout=5000
      wifiTimer:alarm(wifiTimeout,tmr.ALARM_SINGLE, function() checkConnection(cb) end)
      print("Configuring WIFI....")
      wifi.setmode( wifi.STATION )
      station_cfg={}
      station_cfg.ssid=SSID
      station_cfg.pwd=APPWD
      station_cfg.save=false
      wifi.sta.config(station_cfg)
      wifi.sleeptype(wifi.MODEM_SLEEP)
      print("Checking WIFI..." .. wifiTrys)
      wifiTrys = wifiTrys + 1
    else 
     print("Wifi STA connected. IP:")
     print(wifi.sta.getip())
     wifiTrys=0
     return cb()           -- when connected, run callback
    end
  end
end
-- Wifi initialisation
wifiTimer=tmr.create()  -- // detect button bounce

