-- accept data via webserver GET, display on web and screen
--manifest: WifiConnect.lua, webif.lua,httpclient.lua, wificredentials.lua
-- Constants
require("wificredentials")
-- Some control variables
wifiTrys     = 0      -- reset counter of trys to connect to wifi
NUMWIFITRYS  = 20    -- Maximum number of WIFI Testings while waiting for connection
Log={}
Loglim=30;
serinitTimeout=5000       -- timer in ms
serTimer=tmr.create()     -- create timer
require("WifiConnect")
function init_2()
require("OTA2")
end
initTimeout=2000       --  timer in ms
initTimer=tmr.create()  -- start timer
initTimer:alarm(initTimeout,tmr.ALARM_SINGLE,function() checkConnection(init_2) end) 
