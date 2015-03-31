require "cord"

storm.io.set_mode(storm.io.INPUT, storm.io.D9, storm.io.D10, storm.io.D11)
storm.io.set_pull(storm.io.PULL_UP, storm.io.D9, storm.io.D10, storm.io.D11)

whenever = function(button, transition, action)
   return storm.io.watch_all(storm.io[transition], button, action)
end

--ports
sport_broadcast = 1611
service_port = 1614
service_ack_port = 1615

-- service state variables
serv_type = nil
local service_table = {}
local broadcast_reg = {}
local previous = {}
local service_count = 1
local service_button = storm.io.D3
storm.io.set_mode(storm.io.INPUT, service_button)

-- Get type of user using the buttons on the starter shield
user_interface = function()
        print ("Press 1 for Student, 2 for Professor, 3 for Staff:")
        button1 = whenever(storm.io.D9, "RISING", buttonAction(1))
        button2 = whenever(storm.io.D10, "RISING", buttonAction(2))
        button3 = whenever(storm.io.D11, "RISING", buttonAction(3))        
end

function buttonAction(i)
    return function()
        if (i==1) then 
	        serv_type = "student"
            broadcast_reg.student = "true"
        elseif (i == 2) then
	        serv_type = "prof"
            broadcast_reg.prof = "true"
        elseif (i == 3) then
	        serv_type = "staff"
            broadcast_reg.staff = "true"
        end
        broadcast_exists()
        storm.io.cancel_watch(button1)
        storm.io.cancel_watch(button2)
        storm.io.cancel_watch(button3)
        storm.io.watch_all(storm.io["RISING"], service_button, invoke_service)
    end
end

print_services = function()
    print("services")
    local available_choices = {}
    local available_choice_index = 1
    for i = 1, service_count - 1 do
	    if (service_table[i].service_type == serv_type) then
	    	print(i..". "..service_table[i].desc.."\n")
	    	available_choices[available_choice_index] = i
	    	available_choice_index = available_choice_index + 1
	    end
    end
    return available_choices
end

-- Client broadcasts that it exists and listens for ACK
broadcast_sock=storm.net.udpsocket(sport_broadcast, function(payload,from,port) end)
broadcast_exists = function()
        print("broadcasting to master")
        broadcast_reg.id= "a"
        broadcast_reg.desc="NEW_CLIENT"
        local msg = storm.mp.pack(broadcast_reg)
        broadcast_handle = storm.os.invokePeriodically(1000*storm.os.MILLISECOND, function() storm.net.sendto(broadcast_sock, msg, "ff02::1", sport_broadcast) end)
end

ack_sock = storm.net.udpsocket(service_port, 
			   function(payload, from, port)
                  local msg = storm.mp.unpack(payload)
				  print (string.format("from %s port %d: %s",from,port,payload))
                  if (msg.desc == "REG_ACK") then
                    storm.os.cancel(broadcast_handle)
                  elseif (msg.desc == "SERVICE") then
                    handle_service(payload, from, port)
                  elseif (msg.desc == "INVOKE_SERVICE_ACK") then
                    storm.os.cancel(invoke_handle) 
                  end
			   end)

-- Client listens for services and sends ACK
handle_service = function(payload, from, port)
		print("Listening for services")
		local msg = storm.mp.unpack(payload)
        if (msg.desc ~= nil and msg.desc == "SERVICE") then
            for key,val in pairs(msg) do 
			    if (previous[from] ~= nil) then
				    if (key == previous[from].name) then
						local msg_ack = {}
                        msg_ack.id = server_id
				   		msg_ack.name = service_table[service_count-1].name
                        msg_ack.desc = "SERVICE_ACK"
                        local payload_ack = storm.mp.pack(msg_ack) 
				    	storm.net.sendto(ack_sock, payload_ack, from, service_ack_port)
						return 
					end
				end
                if (key ~= "id" and key ~= "desc") then
                    for i = 1, #val.service_type do
						service_table[service_count] = {}
						service_table[service_count].from = from
						service_table[service_count].desc = val.desc
						service_table[service_count].name = key
						service_table[service_count].s = val.s
                    	if (val.service_type[i] == "student") then
							service_table[service_count].service_type = "student"
						elseif (val.service_type[i] == "staff") then
							service_table[service_count].service_type = "staff"
						elseif (val.service_type[i] == "prof") then
							service_table[service_count].service_type = "prof"
 						end
						service_count = service_count + 1
                    end
                end
            end
            local msg_ack = {}
            msg_ack.id = server_id
		    msg_ack.name = service_table[service_count-1].name
            msg_ack.desc = "SERVICE_ACK"
            local payload_ack = storm.mp.pack(msg_ack) 
			storm.net.sendto(ack_sock, payload_ack, from, service_ack_port)
		    previous[from] = {}
		    previous[from].name = service_table[service_count-1].name
       end
    end

invoke_service = function()
    available_choices = print_services()
    local service_choice_string = io.read()
    local service_choice = tonumber(service_choice_string)
     
    local service_msg = {}
    if (service_table[service_choice].s == "setLed") then
	    print("Turn Light on/off (1/0)? ")
        local light = io.read()
    	service_msg.name = service_table[service_choice].name
		service_msg.args = {tonumber(light)}
    end
    service_msg.desc = "INVOKE_SERVICE"
    local service_msg_payload = storm.mp.pack(service_msg)
    invoke_handle = storm.os.invokePeriodically(7*storm.os.SECOND, function () print("invoking", service_msg, service_table[service_choice].from)
        storm.net.sendto(ack_sock, service_msg_payload, service_table[service_choice].from, service_ack_port) end) 
end

user_interface()
cord.enter_loop()
