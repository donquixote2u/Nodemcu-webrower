function checkFiles()
print("checking OTA files\n")
  t={}
  getContent()-- get list (if any) of  files to download
  print("found\n"..buffer)
  for filename in buffer:gmatch("%S+") do
      table.insert(t,filename)
  end
 if (#t < 1) then return end -- stop if no files to download
 -- put init swap here?
 print("getting OTA files\n")
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
   return 
 else               -- filename not nil, so get it
 print("getting file:"..t[x].."\n")
 REQ="/downloads/"..id.."/"..t[x]
 buffer=getHTTP() -- request file into buffer
 local fn=t[x]..".new" -- temp filename has .new appended
 saveFile(fn)       -- save file to flash
 n[x]=fn             -- add to list of tmp files
 getFiles()          -- carry on iterating thru file table
 end      
end	    

function fetchList()	-- wait for internet
 -- if(CONNECTED) then
 if(wifi.sta.getip()) then    -- if ip, then it is connected
    connTimer:stop()
    getHTTP()
    if(buffer==NULL) then
       print("null data\n")
    else   
    print("fetched"..buffer)
    checkFiles() -- wait for list, if not empty, download files
    end
 else
    connCount=connCount+1     --fai after 3 retries
    if(connCount<3) then
        connTimer:alarm(connTimeout,tmr.ALARM_SINGLE,function() fetchList() end) 
    else print("conn failure")
    end
 end
end 

function saveFile(filename)
 getContent()
 -- DEBUG print("writing "..filename.."\n")
 file.remove(filename)
 file.open(filename,"w+")
 file.writeline(buffer)
 file.close()
 collectgarbage()
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
function getHTTP()    -- get page from web server
local BODY={}
BODY[1]="http://"
BODY[2]=SERVER
BODY[3]="/"
BODY[4]=SUBDIR
BODY[5]=REQ
local REQUEST=table.concat(BODY)
buffer=http.get(REQUEST, nil, function(code, data)
    if (code < 0) then
      print("HTTP request failed\n")
      print(REQUEST)
    end
    print("data: "..data)
    return data
  end)
end

-- ======= OTA LOADER =============
 -- check connected, ifnot then connect
 --require("connectIP")  17/7/21 now done in init
 id=node.chipid()   
 SERVER="192.168.0.8" -- set address
 SUBDIR="NODEMCU-OTA" -- set dir
 REQ="/WebUI/?id="..id
 connTimeout=2000       --  timer in ms
 connTimer=tmr.create()  -- start timer
 connCount=0
 buffer=""
 connTimer:alarm(connTimeout,tmr.ALARM_SINGLE,function() fetchList() end) 
 