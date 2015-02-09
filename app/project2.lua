require "cord" -- scheduler / fiber library
LED = require("led")
REG = require "i2creg"
LCD = require "lcd"

print("\nmini-project 2")
brd = LED:new("GP0")
brd:flash(4)
touch = storm.io.D3
prev_reading = 0

function lcd_setup()
    lcd = LCD.new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
end

function write_to_lcd(value)
    cord.new(function ()
        str = string.format("Temperature: %sC", value)
        lcd.init(2, 1)
        lcd.writeString(str)
        local curr_reading = tonumber(value)
        if (curr_reading > prev_reading) then lcd.setBacklight(255, 0, 0)
        elseif (curr_reading < prev_reading) then lcd.setBacklight(0, 0, 255)
        else lcd.setBacklight(0, 255, 0) end
        prev_reading = curr_reading
    end)
end

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

-- client side
count = 0
-- create client socket
csock = storm.net.udpsocket(cport, 
			    function(payload, from, port)
			       print (string.format("echo from %s port %d: %s",from,port,payload))
                   write_to_lcd(payload)
			    end)

-- send echo on each button press
client = function()
   local msg = storm.io.get(touch)
   -- send upd echo to link local all nodes multicast
   storm.net.sendto(csock, msg, "ff02::1", 2001) 
end

-- Use touch sensor to request temperature reading
storm.io.set_mode(storm.io.INPUT, touch)
storm.io.watch_all(storm.io.RISING, touch, function() print("Run client") client() end)

lcd_setup()

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
