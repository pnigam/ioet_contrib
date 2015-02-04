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
    
end

function REG:w(reg, value)
    local extra = 0
    if value % 8 > 0 then extra = 1 end 
    count = 1 + value / 8 + extra
    arr = storm.array.create(count, storm.array.UINT8)
    arr:set(1, reg)
    for i=2,count do arr:set(i, value >> 8)
    storm.i2c.write(storm.i2c.INT + address, storm.i2c.START, arr, function(status) print (status) end)
    -- TODO:
    -- create array with address and value
    -- write
    -- check return value
end

return REG
