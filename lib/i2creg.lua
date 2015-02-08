require "cord"
local REG = {}

-- Create a new I2C register binding
function REG:new(port, address)
    obj = {port=port, address=address}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- Read a given register address
function REG:r(reg)
    -- TODO:
    -- create array with address
    -- write address
    -- read register with RSTART
    -- storm.i2c.read()
    -- check all return values
    local arr = storm.array.create(1, storm.array.UINT8)
    arr:set(1, reg)
    local status = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START, arr)
    print(string.format("Write to address 0x%02x: %d", self.address, status))
    if (status ~= storm.i2c.OK) then return nil end
    status = cord.await(storm.i2c.read, self.port + self.address, storm.i2c.RSTART + storm.i2c.STOP, arr)
    print(string.format("Read from address 0x%02x: %d. Value: %d", self.address, status, arr:get(1)))
    return arr:get(1)
    
end

function REG:w(reg, value)
    -- TODO:
    -- create array with address and value
    -- write
    -- check return value
    local arr = storm.array.create(2, storm.array.UINT8)
    arr:set(1, reg)
    arr:set(2, value)
    local status = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START + storm.i2c.STOP, arr)
    print(string.format("Write to address 0x%02x: %d", self.address, status))
end

return REG
