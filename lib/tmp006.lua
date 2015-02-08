REG = require "i2creg"
bit = require "bit"

local codes = {
--	 TMP006_B0 = -0.0000294,
--	 TMP006_B1 = -0.00000057,
--	 TMP006_B2 = 0.00000000463,
--	 TMP006_C2 = 13.4,
--	 TMP006_TREF = 298.15,
--	 TMP006_A2 = -0.00001678,
--	 TMP006_A1 = 0.00175,
--	 TMP006_S0 = 6.4,

	 TMP006_CFG_RESET    = 0x8000,
	 TMP006_CFG_MODEON   = 0x7000,
	 TMP006_CFG_1SAMPLE  = 0x0000,
	 TMP006_CFG_2SAMPLE  = 0x0200,
	 TMP006_CFG_4SAMPLE  = 0x0400,
	 TMP006_CFG_8SAMPLE  = 0x0600,
	 TMP006_CFG_16SAMPLE = 0x0800,
	 TMP006_CFG_DRDYEN   = 0x0100,
	 TMP006_CFG_DRDY     = 0x0080,

	 TMP006_VOBJ   = 0x00,
	 TMP006_TAMB   = 0x01,
	 TMP006_CONFIG = 0x02,
}

local TMP006 = {}

function TMP006:new()
   local obj = {port=storm.i2c.INT, addr = 0x80, 
                reg=REG:new(storm.i2c.INT, 0x80)}
   setmetatable(obj, self)
   self.__index = self
   return obj
end

function TMP006:init()
    self.reg:w(codes.TMP006_CONFIG, bit.bor(codes.TMP006_CFG_8SAMPLE, codes.TMP006_CFG_MODEON, codes.TMP006_CFG_DRDYEN))
end

function TMP006:readRawDieTemperature()
    local addr = storm.array.create(2, storm.array.UINT8)
    addr:set(1, codes.TMP006_TAMB)
    local rv = cord.await(storm.i2c.write,  self.port + self.addr,  storm.i2c.START, addr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local dat = storm.array.create(2, storm.array.UINT8)
    rv = cord.await(storm.i2c.read,  self.port + self.addr,  storm.i2c.RSTART + storm.i2c.STOP, dat)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    --print(dat:get(1), dat:get(2))
    --print(bit.lshift(dat:get(1), 6),  bit.rshift(dat:get(2), 2))
    return bit.bor(bit.lshift(dat:get(1), 6), bit.rshift(dat:get(2), 2))
end

function TMP006:readRawVoltage()
    local addr = storm.array.create(2, storm.array.UINT8)
    addr:set(1, codes.TMP006_VOBJ)
    local rv = cord.await(storm.i2c.write,  self.port + self.addr,  storm.i2c.START, addr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local dat = storm.array.create(2, storm.array.UINT8)
    rv = cord.await(storm.i2c.read,  self.port + self.addr,  storm.i2c.RSTART + storm.i2c.STOP, dat)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    return bit.bor(bit.lshift(arr:get(1),8), arr:get(2))

end

return TMP006
