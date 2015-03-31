--[[
   echo client as server
   currently set up so you should start one or another functionality at the
   stormshell

--]]

require "cord" -- scheduler / fiber library
LED = require("led")
brd = LED:new("GP0")

print("echo test")
brd:flash(4)

ipaddr = storm.os.getipaddr()
ipaddrs = string.format("%02x%02x:%02x%02x:%02x%02x:%02x%02x::%02x%02x:%02x%02x:%02x%02x:%02x%02x",
			ipaddr[0],
			ipaddr[1],ipaddr[2],ipaddr[3],ipaddr[4],
			ipaddr[5],ipaddr[6],ipaddr[7],ipaddr[8],	
			ipaddr[9],ipaddr[10],ipaddr[11],ipaddr[12],
			ipaddr[13],ipaddr[14],ipaddr[15])

print("ip addr", ipaddrs)
print("node id", storm.os.nodeid())
cport = 49152

local device_table = {}

-- create echo server as handler
server_announ = function()
   ssock_announ = storm.net.udpsocket(1525, 
			       function(payload, from, port)
                  local msg = storm.mp.unpack(payload)
				  brd:flash(1)
				  print (string.format("from %s port %d: %s",from,port,payload))
                  device_table[from] = msg
                  for i, v in pairs(device_table) do for k, v2 in pairs(v) do print(i, k, v2) end end
                  local msg_innov = storm.mp.pack({"printHello"})
				  print(storm.net.sendto(ssock_announ, "fe80::212:6d02:0:301e", from, 1526))
				  brd:flash(1)
			       end)
end

server_invoc = function()
   ssock_invoc = storm.net.udpsocket(1526, 
			       function(payload, from, port)
                  local msg = storm.mp.unpack(payload)
                  for i, v in pairs(msg) do print(i, v) end
				  brd:flash(1)
				  print (string.format("from %s port %d: %s",from,port,payload))
				  -- print(storm.net.sendto(ssock_invoc, payload, from, cport))
				  brd:flash(1)
			       end)
end

server_announ()			-- every node runs the echo server
server_invoc()

-- client side
local svc_manifest = {id="Team1"}              
local msg = storm.mp.pack(svc_manifest)
storm.os.invokePeriodically(5*storm.os.SECOND, function()
    --storm.net.sendto(a_socket, msg, "ff02::1", 1525)
    end)

Button = require("button")
btn1 = Button:new("D9")		-- button 1 on starter shield
blu = LED:new("D2")		-- LEDS on starter shield
grn = LED:new("D3")
red = LED:new("D4")
count = 0
-- create client socket
csock = storm.net.udpsocket(cport, 
			    function(payload, from, port)
			       red:flash(3)
			       print (string.format("echo from %s port %d: %s",from,port,payload))
			    end)

-- send echo on each button press
client = function()
   blu:flash(1)
   local msg = string.format("0x%04x says count=%d", storm.os.nodeid(), count)
   print("send:", msg)
   -- send upd echo to link local all nodes multicast
   storm.net.sendto(csock, msg, "ff02::1", 1526) 
   count = count + 1
   grn:flash(1)
end

                  

-- button press runs client
btn1:whenever("RISING",function() 
		print("Run client")
		client() 
		      end)

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
