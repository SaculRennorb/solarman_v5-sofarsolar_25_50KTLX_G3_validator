package solarman_modbus_register_tester

import "core:net"
import "core:os"
import "core:fmt"
import "core:slice"
import "core:math/rand"
import "core:strings"

import "modbus"
import "solarmanv5"

main :: proc ()
{
	switch os.args[1] {
		case "dump": dump(os.args[2], os.args[3])
		case "show": show(os.args[2], os.args[3])
		case "discover": discover()
		case: fmt.printf(`usage:
	%v dump <logger endpoint> <logger serial>
		dump register values into out.txt
		note: usually port 8899
	%v discover
		broadcast discover message and wait for responses
`, os.args[0], os.args[0])
	}
}

discover :: proc()
{
	fmt.println("sending broadcast...")
	for device in solarmanv5.discover() {
		fmt.println(device)
	}
	fmt.println("done")
}

dump :: proc(logger_endpoint : string, logger_serial_str : string)
{
	socket, err := net.dial_tcp_from_hostname_and_port_string(logger_endpoint)
	for err != nil {
		fmt.println("Failed to open tcp connection:", err)
		socket, err = net.dial_tcp_from_hostname_and_port_string(logger_endpoint)
	}
	defer net.close(socket)
	
	file, ferr := os.open("./out2.txt", os.O_APPEND | os.O_CREATE)
	if ferr != os.ERROR_NONE {
		fmt.println("failed to open logfile"); return
	}
	defer os.close(file)

	line_builder : strings.Builder
	strings.builder_init(&line_builder, 0, 64)



	logger_serial_, _, _ : = fmt._parse_int(logger_serial_str, 0)
	logger_serial := u32le(logger_serial_)
	packet_serial : u16 = 0//u16(rand.int31()) & 0x00ff

	//NOTE(Rennorb): reading is whitelisted by start register, not by the registers taht actually get read.
	// This means you can read 0x0400 - 0x0440, but not 0x0404 - 0x0408.
	// This also means you need to know the exact target you want to read.
	address_step_size : u16 : 1
	requested_register_cnt : u16be : 16 

	response_buffer : [512]u8
	frame : Frame
	for register : u16 = 0; register < 0xffff; register += address_step_size {
		{
			frame = Frame {
				header = solarmanv5.Header {
					start               = solarmanv5.HEADER_START,
					control_code        = solarmanv5.HEADER_CONTROLL_CODE_REQUEST,
					payload_byte_length = size_of(solarmanv5.RequestPayload),
					packet_serial       = u16le(packet_serial),
					logger_serial       = logger_serial,
				},
				payload = solarmanv5.init_request(modbus.init_HRRFrame(modbus.HoldingRegisterRequest { u16be(register), requested_register_cnt })),
			}
			frame.trailer = solarmanv5.intit_trailer(slice.bytes_from_ptr(&frame, size_of(Frame) - size_of(solarmanv5.Trailer))[1/*skip start*/:])
	
			fmt.printf("register#%4x: ", register)

			processed, err := net.send(socket, slice.bytes_from_ptr(&frame, size_of(frame)))
			if processed != size_of(frame) {
				fmt.println("failed to send request", err); return
			}
		}

		/////

		{
			header : solarmanv5.Header
			processed, err := net.recv(socket, slice.bytes_from_ptr(&header, size_of(header)))
			if processed != size_of(header)  {
				fmt.println("failed to receive response header", err); return
			}
			
			assert(header.start         == solarmanv5.HEADER_START)
			assert(header.logger_serial == logger_serial)
			assert(header.control_code  == solarmanv5.HEADER_CONTROLL_CODE_RESPONSE)
			assert(u16(header.packet_serial) & 0x00ff == packet_serial & 0x00ff)
			assert(header.payload_byte_length >= size_of(solarmanv5.ResponsePayloadHeader))
			packet_serial += 1

			payload_len := int(header.payload_byte_length)
			payload := response_buffer[:payload_len]

			processed, err = net.recv(socket, payload)
			if processed != payload_len {
				fmt.println("failed to receive response payload", err); return
			}

			response_trailer : solarmanv5.Trailer
			processed, err = net.recv(socket, slice.bytes_from_ptr(&response_trailer, size_of(response_trailer)))
			if processed != size_of(response_trailer) {
				fmt.println("failed to receive response trailer", err); return
			}
			assert(response_trailer.end == 0x15)

			if payload_len < size_of(solarmanv5.ResponsePayloadHeader) + size_of(modbus.Header) + size_of(modbus.Tailer) {
				fmt.println("malformed payload?: ", payload)
				continue
			}

			payload_data := slice.as_ptr(payload)
			payload_header := (^solarmanv5.ResponsePayloadHeader)(payload_data)^
			modbus_header := (^modbus.Header)(payload_data[size_of(solarmanv5.ResponsePayloadHeader):])^

			if modbus_header.function & modbus.Function.ERROR_BIT == modbus.Function.ERROR_BIT {
				modbus_error := (^modbus.Error)(payload_data[size_of(solarmanv5.ResponsePayloadHeader) + size_of(modbus.Header):])^
				fmt.println("modbus fn:", modbus_header.function &~ modbus.Function.ERROR_BIT , ", error:", modbus_error)
				continue
			}

			modbus_payload := payload[size_of(solarmanv5.ResponsePayloadHeader) + size_of(modbus.Header):payload_len - size_of(modbus.Tailer)]
			trailer := (^modbus.Tailer)(payload_data[payload_len - size_of(modbus.Tailer):])^ //todo

			hrr_header := (^modbus.HoldingRegisterResponseHeader)(slice.as_ptr(modbus_payload))^
			assert(hrr_header.nbytes % 2 == 0) //registers are 16 bit
			modbus_data := slice.reinterpret([]u16be, modbus_payload[size_of(modbus.HoldingRegisterResponseHeader):][:hrr_header.nbytes])
			
	
			fmt.printf("ok %v, crc: %v\n32Bi: %v\n", modbus_data, trailer.crc, slice.reinterpret([]u32be, modbus_data))

			fmt.sbprintf(&line_builder, "register#%4x: ok %v\n32Bi: %v\n", register, modbus_data, slice.reinterpret([]u32be, modbus_data))
			os.write(file, line_builder.buf[:])
			strings.builder_reset(&line_builder)
		}
	}
}

Frame :: struct #packed {
	header  : solarmanv5.Header,
	payload : solarmanv5.RequestPayload,
	trailer : solarmanv5.Trailer,
}



import "devices"

show :: proc(logger_endpoint : string, logger_serial_str : string)
{
	socket, err := net.dial_tcp_from_hostname_and_port_string(logger_endpoint)
	for err != nil {
		fmt.println("Failed to open tcp connection:", err)
		socket, err = net.dial_tcp_from_hostname_and_port_string(logger_endpoint)
	}
	defer net.close(socket)

	logger_serial_, _, _ : = fmt._parse_int(logger_serial_str, 0)
	logger_serial := u32le(logger_serial_)
	packet_serial : u16 = 0//u16(rand.int31()) & 0x00ff

	response_buffer : [512]u8

	show_struct(devices.RegistersSysinfo           , 0x0400, logger_serial, &packet_serial, socket, response_buffer[:])
	show_struct(devices.RegistersOutputData        , 0x0480, logger_serial, &packet_serial, socket, response_buffer[:])
	show_struct(devices.RegistersEmergencyOutput   , 0x0500, logger_serial, &packet_serial, socket, response_buffer[:])
	show_struct(devices.RegistersIndividualStrings , 0x0580, logger_serial, &packet_serial, socket, response_buffer[:])
	show_struct(devices.RegistersHistoricProduction, 0x0680, logger_serial, &packet_serial, socket, response_buffer[:])


	show_struct :: proc($TargetStruct : typeid, target_reg : u16be, logger_serial : u32le, packet_serial : ^u16, socket : net.TCP_Socket, response_buffer : []u8)
	{
		n_registers_to_read : u16be : size_of(TargetStruct) / size_of(u16be)

		frame : Frame
		{
			frame = Frame {
				header = solarmanv5.Header {
					start               = solarmanv5.HEADER_START,
					control_code        = solarmanv5.HEADER_CONTROLL_CODE_REQUEST,
					payload_byte_length = size_of(solarmanv5.RequestPayload),
					packet_serial       = u16le(packet_serial^),
					logger_serial       = logger_serial,
				},
				payload = solarmanv5.init_request(modbus.init_HRRFrame(modbus.HoldingRegisterRequest { target_reg, n_registers_to_read })),
			}
			frame.trailer = solarmanv5.intit_trailer(slice.bytes_from_ptr(&frame, size_of(Frame) - size_of(solarmanv5.Trailer))[1/*skip start*/:])

			fmt.printf("register#%4x: ", target_reg)

			processed, err := net.send(socket, slice.bytes_from_ptr(&frame, size_of(frame)))
			if processed != size_of(frame) {
				fmt.println("failed to send request", err); return
			}
		}

		/////

		{
			header : solarmanv5.Header
			processed, err := net.recv(socket, slice.bytes_from_ptr(&header, size_of(header)))
			if processed != size_of(header)  {
				fmt.println("failed to receive response header", err); return
			}
			
			assert(header.start         == solarmanv5.HEADER_START)
			assert(header.logger_serial == logger_serial)
			assert(header.control_code  == solarmanv5.HEADER_CONTROLL_CODE_RESPONSE)
			assert(u16(header.packet_serial) & 0x00ff == packet_serial^ & 0x00ff)
			assert(header.payload_byte_length >= size_of(solarmanv5.ResponsePayloadHeader))
			packet_serial^ += 1

			payload_len := int(header.payload_byte_length)
			payload := response_buffer[:payload_len]

			processed, err = net.recv(socket, payload)
			if processed != payload_len {
				fmt.println("failed to receive response payload", err); return
			}

			response_trailer : solarmanv5.Trailer
			processed, err = net.recv(socket, slice.bytes_from_ptr(&response_trailer, size_of(response_trailer)))
			if processed != size_of(response_trailer) {
				fmt.println("failed to receive response trailer", err); return
			}
			assert(response_trailer.end == 0x15)

			if payload_len < size_of(solarmanv5.ResponsePayloadHeader) + size_of(modbus.Header) + size_of(modbus.Tailer) {
				fmt.println("malformed payload?: ", payload)
				return
			}

			payload_data := slice.as_ptr(payload)
			payload_header := (^solarmanv5.ResponsePayloadHeader)(payload_data)^
			modbus_header := (^modbus.Header)(payload_data[size_of(solarmanv5.ResponsePayloadHeader):])^

			if modbus_header.function & modbus.Function.ERROR_BIT == modbus.Function.ERROR_BIT {
				modbus_error := (^modbus.Error)(payload_data[size_of(solarmanv5.ResponsePayloadHeader) + size_of(modbus.Header):])^
				fmt.println("modbus fn:", modbus_header.function &~ modbus.Function.ERROR_BIT , ", error:", modbus_error)
				return
			}

			modbus_payload := payload[size_of(solarmanv5.ResponsePayloadHeader) + size_of(modbus.Header):payload_len - size_of(modbus.Tailer)]
			trailer := (^modbus.Tailer)(payload_data[payload_len - size_of(modbus.Tailer):])^ //todo

			hrr_header := (^modbus.HoldingRegisterResponseHeader)(slice.as_ptr(modbus_payload))^
			assert(hrr_header.nbytes % 2 == 0) //registers are 16 bit


			modbus_data := slice.as_ptr(modbus_payload[size_of(modbus.HoldingRegisterResponseHeader):][:hrr_header.nbytes])

			strings_info := (^TargetStruct)(modbus_data)^
			devices.print(strings_info)
		}
	}
}