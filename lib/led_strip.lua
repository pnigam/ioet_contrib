require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
bit = require "bit"

local LED_STRIP = {}

datapin = storm.io.D6
clockpin = storm.io.D7
nled = 2

storm.io.set_mode(storm.io.OUTPUT, datapin)
storm.io.set_mode(storm.io.OUTPUT, clockpin)

function latchleds()
    storm.io.set(0, datapin)
    cord.await(storm.os.invokeLater, storm.os.MILLISECOND)  
    local i = 0   
    for i=1, 8*nled do
        storm.io.set(1, clockpin)
        cord.await(storm.os.invokeLater, storm.os.MILLISECOND)
        storm.io.set(0, clockpin)
    end
end

function color(r, g, b)
    r = bit.band(r, 31)
    g = bit.band(g, 31)
    b = bit.band(b, 31)
    return bit.bor(bit.bor(bit.lshift(b, 10), bit.lshift(r, 5)), g)
end

function init() 
    local i = 0
    for i=1, nled do
        LED_STRIP[i] = color(31, 31, 31)
    end
    show()
end

function show()
    local i = 0
    local j = 0
    for i=1,nled do
        print(LED_STRIP[i])
        storm.io.set(1, datapin)
        cord.await(storm.os.invokeLater, storm.os.MILLISECOND)
        storm.io.set(1, clockpin)
        cord.await(storm.os.invokeLater, storm.os.MILLISECOND)
        storm.io.set(0, clockpin)
        j = 16384
        while (j ~= 0) do
            if (bit.band(LED_STRIP[i], j) ~= 0) then 
                storm.io.set(1, datapin)
            else 
                storm.io.set(0, datapin) 
            end
            cord.await(storm.os.invokeLater, storm.os.MILLISECOND)
            storm.io.set(1, clockpin)
            cord.await(storm.os.invokeLater, storm.os.MILLISECOND)
            storm.io.set(0, clockpin)
            j = j / 2
        end
    end
    latchleds()
end

cord.new(
    function()
        init()
        --[[for strip=1, nled do
            LED_STRIP[strip] = color(31, 0, 0)
        end
        show()]]--
    end)

cord.enter_loop()
