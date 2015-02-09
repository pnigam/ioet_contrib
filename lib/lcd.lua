REG = require "i2creg"
string = require "string"

local codes = {
    LCD_CLEARDISPLAY = 0x01,
    LCD_RETURNHOME = 0x02,
    LCD_ENTRYMODESET = 0x04,
    LCD_DISPLAYCONTROL = 0x08,
    LCD_CURSORSHIFT = 0x10,
    LCD_FUNCTIONSET = 0x20,
    LCD_SETCGRAMADDR = 0x40,
    LCD_SETDDRAMADDR = 0x80,

    --lags for display entry mode
    LCD_ENTRYRIGHT = 0x00,
    LCD_ENTRYLEFT = 0x02,
    LCD_ENTRYSHIFTINCREMENT = 0x01,
    LCD_ENTRYSHIFTDECREMENT = 0x00,

    --lags for display on/off control
    LCD_DISPLAYON = 0x04,
    LCD_DISPLAYOFF = 0x00,
    LCD_CURSORON = 0x02,
    LCD_CURSOROFF = 0x00,
    LCD_BLINKON = 0x01,
    LCD_BLINKOFF = 0x00,

    --flags for display/cursor shift
    LCD_DISPLAYMOVE = 0x08,
    LCD_CURSORMOVE = 0x00,
    LCD_MOVERIGHT = 0x04,
    LCD_MOVELEFT = 0x00,

    --flags for function set
    LCD_8BITMODE = 0x10,
    LCD_4BITMODE = 0x00,
    LCD_2LINE = 0x08,
    LCD_1LINE = 0x00,
    LCD_5x10DOTS = 0x04,
    LCD_5x8DOTS = 0x00,

    LCD_COMMAND = 0x80,
    LCD_WRITE = 0x40,
    LED_OUTPUT = 0x08,
    REG_RED    = 0x04,
    REG_GREEN = 0x03,
    REG_BLUE  = 0x02,
}

local LCD = {}

LCD.new = function(lcd_port, lcd_addr, rgb_port, rgb_addr)
    LCD.lcdreg = REG:new(lcd_port, lcd_addr)
    LCD.rgbreg = REG:new(rgb_port, rgb_addr)
    return LCD
end

LCD.command = function(val)
    LCD.lcdreg:w(codes.LCD_COMMAND, val)
end

LCD.write = function (char)
    LCD.lcdreg:w(codes.LCD_WRITE, char)
end

LCD.writeString = function(str)
    local i
    for i = 1, string.len(str) do
        LCD.write(string.byte(str:sub(i, i)))
    end
end

LCD.init = function(lines, dotsize)
            LCD._df = 0
            if lines == 2 then LCD._df = codes.LCD_2LINE end
            LCD._df = LCD._df + codes.LCD_8BITMODE
            LCD.nl = lines
            LCD._dc = 0
            LCD._dm = codes.LCD_ENTRYLEFT + codes.LCD_ENTRYSHIFTDECREMENT;
            LCD._cl = 0
            if dotsize ~=0 and lines ~= 1 then LCD._df = bit.bor(LCD._df, codes.LCD_5x8DOTS) end
            -- seriously, the chip requires this...
            cord.await(storm.os.invokeLater, 200*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(codes.LCD_FUNCTIONSET + LCD._df)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(0x08)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(0x01)
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            LCD.command(0x6)
            cord.await(storm.os.invokeLater, 200*storm.os.MILLISECOND)
            LCD._dc  = codes.LCD_DISPLAYON + codes.LCD_CURSORON + codes.LCD_BLINKON
            LCD.display()
            cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)

            LCD.rgbreg:w(0, 0)
            LCD.rgbreg:w(1, 0)
            LCD.rgbreg:w(codes.LED_OUTPUT, 0xAA)

end
LCD.setCursor = function(row, col)
    if row == 0 then
        col = bit.bor(col, 0x80)
    else
        col = bit.bor(col, 0xc0)
    end
    LCD.command(col)
end
LCD.display = function ()
    LCD._dc = bit.bor(LCD._dc, codes.LCD_DISPLAYON)
    LCD.command(codes.LCD_DISPLAYCONTROL + LCD._dc)
end
LCD.nodisplay = function ()
    LCD._dc = bit.bor(LCD._dc, bit.bnor(codes.LCD_DISPLAYON))
    LCD.command(codes.LCD_DISPLAYCONTROL + LCD._dc)
end
LCD.clear = function ()
    LCD.command(codes.LCD_CLEARDISPLAY)
    cord.await(storm.os.invokeLater, 2*storm.os.MILLISECOND)
end
LCD.setBacklight = function(red, green, blue)
    LCD.rgbreg:w(codes.REG_RED, red)
    LCD.rgbreg:w(codes.REG_GREEN, green)
    LCD.rgbreg:w(codes.REG_BLUE, blue)
end

return LCD
