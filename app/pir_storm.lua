require ("cord")
calibrationTime=30
pirPin = storm.io.D4

function setup()
	storm.io.set_mode(storm.io.INPUT, pirPin)
	storm.io.set(0, pirPin)
	print("Calibrating sensor")
	for i=0, calibrationTime do
		cord.await(storm.os.invokeLater, storm.os.SECOND)
		print(".")
	end
	print("Done. Sensor ready")
	cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
end

function loop()
	pirVal= storm.io.get(pirPin)
	if(pirVal ==1) then print("Motion Detected") end
end 

cord.new(function()
	setup()
	
	while (1) do
		loop()
		cord.await(storm.os.invokeLater, storm.os.SECOND)
	end
	end) --end of cord.new function

cord.enter_loop()

