package solarmanv5

import "../modbus"

Header :: struct #packed {
	start               : u8,
	payload_byte_length : u16le,
	control_code        : u16le,
	packet_serial       : u16le,
	logger_serial       : u32le,
}

HEADER_START : u8 : 0xa5
HEADER_CONTROLL_CODE_REQUEST : u16le : 0x4510
HEADER_CONTROLL_CODE_RESPONSE : u16le : 0x1510

RequestPayload :: struct #packed {
	frame_type         : u8,
	sensor_type        : u16le,
	total_working_time : u32le,
	power_on_time      : u32le,
	offset_time        : u32le,
	modbus_frame       : modbus.HRRFrame,
}

init_request :: proc(frame : modbus.HRRFrame) -> RequestPayload
{
	return RequestPayload {
		frame_type         = 0x02,
		sensor_type        = 0,
		total_working_time = 0,
		power_on_time      = 0,
		offset_time        = 0,
		modbus_frame       = frame,
	}
}

ResponsePayloadHeader :: struct #packed {
	frame_type         : ResponseFrameType,
	status             : ResponseStatus,
	// Denotes the number of seconds that data logging stick has been operating. Other implementations have this field named TimeOutOfFactory.
	total_working_time : u32le,
	// Denotes the current uptime of the data logging stick in seconds.
	power_on_time      : u32le,
	// Denotes offset timestamp, in seconds. This is defined as current data logging stick timestamp minus Total Working Time.
	offset_time        : u32le,
}

ResponseFrameType :: enum u8 {
	KEEP_ALIVE       = 0, // or solarman cloud
	DATALOBBER_STICK = 0x01,
	SOLAR_INVERTER   = 0x02,
}

ResponseStatus :: enum u8 {
	REAL_TIME = 0x01,
}

Trailer :: struct #packed {
	checksum : u8,
	end      : u8,
}

intit_trailer :: proc(frame_data : []u8) -> Trailer {
	checksum : u8 = 0

	for b in frame_data { checksum += b }

	return Trailer {
		checksum = checksum,
		end = TRAILER_END,
	}
}

TRAILER_END : u8 : 0x15
