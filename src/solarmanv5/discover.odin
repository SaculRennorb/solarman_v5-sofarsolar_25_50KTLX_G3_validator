package solarmanv5

import "core:net"
import "core:runtime"
import "core:strconv"
import "core:time"

import "../mac"

DeviceInfo :: struct {
	ip_addr : net.Address,
	mac     : mac.MacAddress,
	serial  : u64,
}


discover :: proc() -> (devices : [dynamic]DeviceInfo)
{
	socket, _err := net.make_unbound_udp_socket(net.Address_Family.IP4)
	defer net.close(socket)
	net.set_option(socket, .Reuse_Address, true)
	net.set_option(socket, .Broadcast, true)
	net.set_option(socket, .Receive_Timeout, time.Second * 10)
	
	broadcast_addr := net.IP4_Address{ 0xff, 0xff, 0xff, 0xff } //technically not correct, but good neough for now 
	broadcast_ep := net.Endpoint { broadcast_addr, 48989 }

	broadcast_text :string: "WIFIKIT-214028-READ"
	broadcast := (transmute(runtime.Raw_String)broadcast_text).data[:20]

	net.send_udp(socket, broadcast, broadcast_ep)

	buffer : [1024]u8
	for true {
		read, _, err := net.recv_udp(socket, buffer[:])
		if err == net.UDP_Recv_Error.Timeout { break }

		response := buffer[:read]

		offset := 0

		info : DeviceInfo
		
		for i in 0..<read {
			if response[i] != ',' { continue }

			info.ip_addr = net.parse_address(string(response[:i]))
			offset = i + 1
			break
		}
		for i in offset..<read {
			if response[i] != ',' { continue }

			info.mac = mac.parse(string(response[offset:i]))
			offset = i + 1
			break
		}
		serial, _ := strconv.parse_u64_of_base(string(response[offset:]), 10)
		info.serial = serial

		append(&devices, info)
	}

	return
}
