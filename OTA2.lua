function checkFiles()
  t={}
  getContent()-- get list (if any) of  files to download
  for filename in buffer:gmatch("%S+") do
      table.insert(t,filename)
  end
 if (#t < 1) then return end -- stop if no files to download
 -- put init swap here?
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
 if(CONNECTED) then
    tmr.stop(3)
    buffer=getHTTP()
 else
    tmr.alarm( 3, 2000, 0, fetchList)
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
return http.get(REQUEST, nil, function(code, data)
    if (code < 0) then
      print("HTTP request failed")
      print(REQUEST)
    end
    return data
  end)
end

-- ======= OTA LOADER =============
 -- check connected, ifnot then connect
 --require("connectIP")  17/7/21 now done in init
 id=node.chipid()   
 SERVER="192.168.0.2" -- set address
 SUBDIR="NODEMCU-OTA" -- set dir
 REQ="/WebUI/?id="..id
 buffer=""
 fetchList()
 checkFiles() -- wait for list, if not empty, download files
