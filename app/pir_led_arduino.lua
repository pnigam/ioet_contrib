require ("cord")
calibrationTime=30
pirPin1 = storm.io.D4
outputPin1 = storm.io.D5
pirPin2 = storm.io.D6
outputPin2 = storm.io.D7

function setup()
	storm.io.set_mode(storm.io.INPUT, pirPin1)
	storm.io.set_mode(storm.io.OUTPUT, outputPin1)
	storm.io.set(0, outputPin1)
	storm.io.set_mode(storm.io.INPUT, pirPin2)
	storm.io.set_mode(storm.io.OUTPUT, outputPin2)
	storm.io.set(0, outputPin2)
	print("Calibrating sensor")
	for i=0, calibrationTime do
		cord.await(storm.os.invokeLater, storm.os.SECOND)
		print(".")
	end
	print("Done. Sensor ready")
	cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
end

function loop()
	pirVal1= storm.io.get(pirPin1)
    storm.io.set(pirVal1, outputPin1)
	pirVal2= storm.io.get(pirPin2)
    storm.io.set(pirVal2, outputPin2)
	if (pirVal1 == 1) then print("Motion Detected 1") 
    else print("Motion Not Detected 1") end
    if (pirVal2 == 1) then print("Motion Detected 2")
    else print("Motion Not Detected 2") end

end 

cord.new(function()
	setup()
	
	while (1) do
		loop()
		cord.await(storm.os.invokeLater, storm.os.SECOND)
	end
	end) --end of cord.new function

cord.enter_loop()

