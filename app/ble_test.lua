require "cord"
--0x301b
--c8:e5:41:f8:0a:31   b5
function onconnect(state)
   if tmrhandle ~= nil then
       storm.os.cancel(tmrhandle)
       tmrhandle = nil
   end
   if state == 1 then
       storm.os.invokePeriodically(1*storm.os.SECOND, function()
           --print ("reached")
           tmrhandle = storm.bl.notify(char_handle, 
              string.format("Time: %d", storm.os.now(storm.os.SHIFT_16)))
       end)
   end
end


storm.bl.enable("test", onconnect, function()
   local svc_handle = storm.bl.addservice(0x1337)
   char_handle = storm.bl.addcharacteristic(svc_handle, 0x1338, function(x)
       print ("received: ",x)
   end)
end)
cord.enter_loop()
