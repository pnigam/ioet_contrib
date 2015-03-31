require "cord" -- scheduler / fiber library
TMP006 = require "tmp006"
LCD = require "lcd"

local buzzer = storm.io.D2
local led = storm.io.D3
local relay = storm.io.D4
storm.io.set_mode(storm.io.OUTPUT, buzzer)
storm.io.set_mode(storm.io.OUTPUT, led)
storm.io.set_mode(storm.io.OUTPUT, relay)

local server_ip = "ff02::1"
local broadcast_port = 1611
local ack_port = 1612
local service_port = 1622
local server_port = 1623
--local ping_port = 1624 
--local ping_resp_port = 1625

local service_count = 1
service_table = {}
service_table.id = "a"
service_table.desc = "SERVICE"

local services = {}
services[1] = "getTemp"
services[2] = "playSong"
services[3] = "setLights"
services[4] = "dispString"
--services[5] = "setRelay"
local service_messages = {
    getTemp = {s = "subscribeToTemp", desc = "A-temp", service_type = {"student", "prof"} },
    dispString = {s = "lcdDisp", desc = "A-lcd", service_type = {"student"} },
    setLights = {s = "setLed", desc = "A-led", service_type = {"student", "prof", "staff"} },
    --setRelay = {s = "setRelay", desc = "A-relay", service_type = {"student"} },
    playSong = {s = "setBuzzer", desc = "A-buzzer", service_type = {"student"} },
}

function temp_setup() 
	cord.new(function() 
	    tmp = TMP006:new()
	    tmp:init()
	 end)
end

function lcd_setup()
    lcd = LCD.new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
end

write_to_screen = function(str)
    cord.new(function ()
        lcd.init(2, 1)
        lcd.writeString(str)
    end)
end

function set_led(value)
    storm.io.set(value,led)
end

function set_buzzer(value)
    storm.io.set(value, buzzer)
end
--[[
function set_relay(value)
    storm.io.set(value,led)
end
]]--
broadcast_sock = storm.net.udpsocket(broadcast_port, function(payload, from, port)  end)
service_broadcast = function()
   if (service_count > 1) then
       service_table[services[service_count-1]] = nil
   end
   service_table[services[service_count]] = service_messages[services[service_count]]
   local msg = storm.mp.pack(service_table)
   print(msg)
   storm.net.sendto(broadcast_sock, msg, server_ip, broadcast_port)
end

service_sock = storm.net.udpsocket(service_port, function(payload, from, port) 
                      print(payload)
                      local msg = storm.mp.unpack(payload)
                      resp = {}
                      resp.name = msg.name
                      resp.id = service_table.id
                      resp.payload = ""
                      if (msg.name == "dispString") then 
                          write_to_screen(msg.args[1])
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "setLights") then 
                          set_led(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "setRelay") then 
                          set_relay(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "playSong") then 
                          set_buzzer(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "getTemp") then
                              cord.new(function() 
	                            resp.payload = tmp:readDieTempC()
                                service_respond(storm.mp.pack(resp))
                              end)
                      end
 end)
service_listen = function(payload, from, port) 
                      print(payload)
                      local msg = storm.mp.unpack(payload)
                      resp = {}
                      resp.name = msg.name
                      resp.id = service_table.id
                      resp.payload = ""
                      if (msg.name == "dispString") then 
                          write_to_screen(msg.args[1])
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "setLights") then 
                          set_led(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
--[[                      elseif (msg.name == "setRelay") then 
                          set_relay(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp)) ]]--
                      elseif (msg.name == "playSong") then 
                          set_buzzer(tonumber(msg.args[1]))
                          resp.payload = "SUCCESS"
                          service_respond(storm.mp.pack(resp))
                      elseif (msg.name == "getTemp") then
                              cord.new(function() 
	                            resp.payload = tmp:readDieTempC()
                                service_respond(storm.mp.pack(resp))
                              end)
                      end
end

response_sock = storm.net.udpsocket(server_port, function(payload, from, port) end)
service_respond = function(msg)
   print("responding: ", msg)
   storm.net.sendto(response_sock, msg, server_ip, server_port)
end

ack_listen = function() 
    ack_sock = storm.net.udpsocket(ack_port, 
			   function(payload, from, port)
                  local msg = storm.mp.unpack(payload)
				  print (string.format("from %s port %d: %s",from,port,payload))
                  server_ip = from
                  if msg.name == services[service_count] then service_count = service_count + 1 end
                  storm.os.cancel(broadcast_handle)
                  if service_count <= #services then
                      broadcast_handle = storm.os.invokePeriodically(500*storm.os.MILLISECOND, service_broadcast)
                  end
                  --service_listen()
			   end)
end

lcd_setup()
temp_setup()
ack_listen()
broadcast_handle = storm.os.invokePeriodically(1000*storm.os.MILLISECOND, service_broadcast)

cord.enter_loop() -- start event/sleep loop
