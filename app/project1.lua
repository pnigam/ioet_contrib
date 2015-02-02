require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
math = require("math")
shield = require("starter") -- interfaces for resources on starter shield

print ("Whack-A-LED")

shield.Button.start()		-- enable LEDs
shield.LED.start()

map = {[1]="blue",[2]="green",[3]="red"}
score = 0

function initializeLEDFlash(duration)
   red = storm.os.invokePeriodically(4*storm.os.SECOND, function() shield.LED.flash("red", math.random(3000)) end )
   storm.os.invokeLater(duration*1*storm.os.SECOND, function() storm.os.cancel(red) end)

   green = storm.os.invokePeriodically(3*storm.os.SECOND, function() shield.LED.flash("green", math.random(2000)) end )
   storm.os.invokeLater(duration*1*storm.os.SECOND, function() storm.os.cancel(green) end)

   blue = storm.os.invokePeriodically(5*storm.os.SECOND, function() shield.LED.flash("blue", math.random(3000)) end)
   storm.os.invokeLater(duration*1*storm.os.SECOND, function() storm.os.cancel(blue) end)

   storm.os.invokeLater(duration*1*storm.os.SECOND, function() storm.os.cancel(blue) end)
end

function buttonAction(button)
   return function() 
      if (shield.LED.isOn(map[button])) then
          shield.LED.off(map[button])
          score = score + 1
          print (string.format("%s %d", "Your score: ", score))
      else
          score = score - 1
          shield.Buzz.timedBuzz(1)
          print (string.format("%s %d", "Your score: ", score))
      end
 
   end
end

function endGame() 
    print ("GAME OVER")
    print (string.format("%s %d", "Final Score: ", score))
end

gameLength = 10
initializeLEDFlash(gameLength)
shield.Button.timedWhenever(1, "RISING", buttonAction(1), gameLength)
shield.Button.timedWhenever(2, "RISING", buttonAction(2), gameLength)
shield.Button.timedWhenever(3, "RISING", buttonAction(3), gameLength)
storm.os.invokeLater(gameLength * storm.os.SECOND, function() endGame() end)
cord.enter_loop() -- start event/sleep loop


