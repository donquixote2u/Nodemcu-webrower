function checkFiles()
  t={}
  getContent()-- get list (if any) of  files to download
  for filename in buffer:gmatch("%S+") do
   -- DEBUG print("filename:"..filename)
   table.insert(t,filename)
  end
 if (#t < 1) then return end -- stop if no files to download
 if(file.exists("init.ota")) then
    print("switching to OTA mode") 
    if (file.exists("init.bak")) then
       file.remove("init.bak")
    end   -- swap ota init file in and reboot
    file.rename("init.lua","init.bak")
    file.rename("init.ota","init.lua")
    node.restart()  -- reboot in OTA update mode
 else   -- no init.ota file,
    if (file.exists("init.bak")) then -- in OTA mode, so
       file.rename("init.lua","init.ota") -- set up normal
       file.rename("init.bak","init.lua") -- mode
    end
 end   
 x=0    --reset index for getFiles to use
 n={}   -- init temp file table
 getFiles()
end

function getFiles()
 x=x+1
 if(t[x]==nil) then		-- no more files to get, so rename them
   for y,filename in pairs(n) do -- traverse table of tmp files
    file.remove(t[y])   -- delete old if exists
    file.rename(filename,t[y]) -- rename tmp file to same as list
    print(filename.." renamed "..t[y].."\n") 
   end
   t=nil
   n=nil 
   print("deleting server files\n")
   REQ="/WebUI/?id="..id.."&action=delete"		-- delete server files if ok
   sendReq() -- request file into buffer
   handler="printBuffer"
   receivePage()
   return 
 else               -- filename not nil, so get it
 print("getting file:"..t[x].."\n")
 REQ="/downloads/"..id.."/"..t[x]
 sendReq() -- request file into buffer
 handler="saveFile" -- wait for file 
 receivePage()
 end      
end	    

function fetchList()	-- wait for internet
 if(CONNECTED) then
    tmr.stop(3)
    sendReq()
 else
    tmr.alarm( 3, 2000, 0, fetchList)
 end
end 

function receivePage()    -- wait for file list
 if(RECEIVED) then
    tmr.stop(4)
    _G[handler]()
 else
    tmr.alarm( 4, 2000, 0, receivePage)
 end
end

function saveFile()
 local fn=t[x]..".new" -- temp filename has .new appended
 n[x]=fn             -- add to list of tmp files
 getContent()
 -- DEBUG print("writing "..filename.."\n")
 file.remove(fn)
 file.open(fn,"w+")
 file.writeline(buffer)
 file.close()
 collectgarbage()
 getFiles()          -- carry on iterating thru file table
end

function getContent()
  for line in buffer:gmatch("[^\r\n]+") do
       i,j=string.find(line,"Length:") -- calc content size
       if(j~=nil) then      -- get content 
         clength=string.sub(line,j+1)
         buffer=string.sub(buffer,string.len(buffer)-clength)
       end
   end
end

function printBuffer()
  print("delete response = "..buffer)
end  
-- ======= OTA LOADER =============
 -- check connected, ifnot then connect
 require("connectIP")
 require("getHTTP") --load webclient func
 id=node.chipid()   
 connParm["IP"]="192.168.0.4" -- set address
 connParm["NAME"]="alpha" -- set host
 connParm["SUBDIR"]="NODEMCU-OTA" -- set dir
 REQ="/WebUI/?id="..id
 buffer=""
 fetchList() -- wait until connect, then get update List
 handler="checkFiles"
 receivePage()  -- wait for list, if not empty, download files