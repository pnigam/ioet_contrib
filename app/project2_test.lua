require "cord"
sh = require "stormsh"
ACC = require "acc"
REG = require "i2creg"
LCD = require "lcd"
TMP006 = require "tmp006"

function scan_i2c()
    for i=0x00,0xFE,2 do
        local arr = storm.array.create(1, storm.array.UINT8)
        local rv = cord.await(storm.i2c.read,  storm.i2c.INT + i,  
                        storm.i2c.START + storm.i2c.STOP, arr)
        if (rv == storm.i2c.OK) then
            print (string.format("Device found at 0x%02x",i ));
        end
    end
end

function temp_setup() 
	cord.new(function() 
	    local a = TMP006:new()
	    a:init()
	    local i = 0
	    while true do
	       i = i + 1
	       print(i, a:readDieTempC())
	    end
	 end)
end

function lcd_setup()
    lcd = LCD.new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
end

function test_lcd()
    cord.new(function ()
        lcd.init(2, 1)
        lcd.writeString("TESTING")
    end)
end

-- start a coroutine that provides a REPL
sh.start()

-- enter the main event loop. This puts the processor to sleep
-- in between events
cord.enter_loop()
