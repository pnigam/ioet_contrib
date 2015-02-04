ACCEL_WHOAMI = 0x0D
ACCEL_WHOAMI_VAL = 0xC7
ACCEL_CTRL_REG1 = 0x2A
ACCEL_M_CTRL_REG1 = 0x5B
ACCEL_M_CTRL_REG2 = 0x5C
ACCEL_XYZ_DATA_CFG = 0x0E
ACCEL_CTRL_REG1 = 0x2A

local ACC = {}

function ACC:new()
   local obj = {port=storm.i2c.INT, addr = 0x3c, 
                reg=REG:new(storm.i2c.INT, 0x3c)}
   setmetatable(obj, self)
   self.__index = self
   return obj
end


function ACC:init()
    local tmp = self.reg:r(ACCEL_WHOAMI)
    assert (tmp == ACCEL_WHOAMI_VAL, "accelerometer insane")

    --lets put it into standby
    self.reg:w(ACCEL_CTRL_REG1, 0x00);

    --Config magnetometer
    self.reg:w(ACCEL_M_CTRL_REG1, 0x1f)
    self.reg:w(ACCEL_M_CTRL_REG2, 0x20)

    --config accelerometer
    self.reg:w(ACCEL_XYZ_DATA_CFG, 0x01)

    --go out of standby
    self.reg:w(ACCEL_CTRL_REG1, 0x0D)
end

return ACC

