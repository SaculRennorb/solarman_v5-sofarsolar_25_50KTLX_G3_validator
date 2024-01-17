package sofarsolar_25_50KTLX_G3

import "core:fmt"

print :: proc{ print_sys_info, print_output, print_strings_info, print_emergency_output, print_historic_production }

// 0x0400 - complete
RegistersSysinfo :: struct #packed {
	validity_mask : u64be,
	state : State,
	faults_1_to_18 : [18]u16be,
	power_on_countdown : u16be,
	// °C
	temperature_environment : [2]i16be,
	// °C
	temperature_heatsink : [6]i16be,
	// °C
	temperature_inverter : [3]i16be,
	// °C  reserved
	_ : [3]i16be,
	// minutes
	generation_time_today : u16be,
	//minutes
	generation_time_total : u32be,
	//minutes
	service_time_total : u32be,
	// kOhm
	insulation_resistance : u16be,
	systemtime_year : u16be,
	systemtime_month : u16be,
	systemtime_date : u16be,
	systemtime_hour : u16be,
	systemtime_minute : u16be,
	systemtime_second : u16be,
	faults_19_to_27 : [9]u16be,
}

print_sys_info :: proc(data : RegistersSysinfo)
{
	fmt.printf("%#v\nfault 1-18: %16b\nfault 19-27: %16b\n", data, data.faults_1_to_18, data.faults_19_to_27)
}

State :: enum u16be {
	WAITING = 0,
	DETECTION,
	GRID_CONNECTED,
	EMERGENCY_POWER_SUPPLY,
	RECOVERABLE_FAULT,
	PERMANENT_FAULT,
	UPGRADE,
	SELF_CHARGING,
	SVG,
	PID,
}

// 0x0480 
RegistersOutputData :: struct #packed {
	validity_mask : u64be,
	// Hz, * 0.01
	grid_frequency : u16be,
	// kW, * 0.01
	total_output_power_active : i16be,
	// kW, * 0.01
	total_output_power_reactive : i16be,
	// kW, * 0.01
	total_output_power_apparent : i16be,
	// kW, * 0.01
	total_pcc_power_active : i16be,
	// kW, * 0.01
	total_pcc_power_reactive : i16be,
	// kW, * 0.01
	total_pcc_power_apparent : i16be,
	_ : u16be,
	_ : u16be,
	r, s, t : PhaseOutput,
	// kW, * 0.01
	active_power_pv_external : u16be,
	// kW, * 0.01
	total_active_power_load_system : u16be,
	//might be wrong 
	//l1, l2, l3 : PhaseToNOutput,
	// // V, * 0.1  bewtween R/S
	// voltage_line_l1 : u16be,
	// // V, * 0.1  bewtween S/T
	// voltage_line_l2 : u16be,
	// // V, * 0.1  bewtween T/R
	// voltage_line_l3 : u16be,
	// // *0.001
	// total_power_factor : i16be,
}

PhaseOutput :: struct #packed {
	// V, * 0.1
	voltage_phase : u16be,
	// A, * 0.01
	output_current : u16be,
	// kW, * 0.01
	output_active_power : i16be,
	// kW, * 0.01
	output_reactive_power : i16be,
	//  * 0.001
	output_power_factor : i16be,
	// A, * 0.01
	pcc_current : u16be,
	// kW, * 0.01
	pcc_active_power : i16be,
	// kW, * 0.01
	pcc_reactive_power : i16be,
	//  * 0.001
	pcc_power_factor : i16be,
	_ : u16be,
	_ : u16be,
}

PhaseToNOutput :: struct #packed {
	// V, * 0.1
	voltage_phase : u16be,
	// A, * 0.01
	output_current : u16be,
	// kW, * 0.01
	output_active_power : i16be,
	// A, * 0.01
	pcc_current : u16be,
	// kW, * 0.01
	pcc_active_power : i16be,
}

print_output :: proc(data : RegistersOutputData)
{
	fmt.printf(`output:
	mask: %64b
	grid frequency             : %vHz
	total output active   power: %vkW
	total output reactive power: %vkW
	total output apparent power: %vkW
	total pcc    active   power: %vkW
	total pcc    reactive power: %vkW
	total pcc    apparent power: %vkW
`,
		data.validity_mask,
		f32(data.grid_frequency) * 0.01,
		f32(data.total_output_power_active) * 0.01,
		f32(data.total_output_power_reactive) * 0.01,
		f32(data.total_output_power_apparent) * 0.01,
		f32(data.total_pcc_power_active) * 0.01,
		f32(data.total_pcc_power_reactive) * 0.01,
		f32(data.total_pcc_power_apparent) * 0.01,
	)
	fmt.print("\tphase R:")
	print_phase(data.r)
	fmt.print("\tphase S:")
	print_phase(data.s)
	fmt.print("\tphase T:")
	print_phase(data.t)

	fmt.printf(`	active power external: %vkW
	total system load    : %vkW
`,
	f32(data.active_power_pv_external) * 0.01,
	f32(data.total_active_power_load_system) * 0.01,
)

	// fmt.print("\tphase 1 to N:")
	// print_phase_to_n(data.l1)
	// fmt.print("\tphase 2 to N:")
	// print_phase_to_n(data.l2)
	// fmt.print("\tphase 3 to N:")
	// print_phase_to_n(data.l3)


	print_phase :: proc(data : PhaseOutput)
	{
		fmt.printf(`
		voltage              : %vV
		output current       : %vA
		output active   power: %vkW
		output reactive power: %vkW
		output power factor  : %v
		pcc    current       : %vA
		pcc    active   power: %vkW
		pcc    reactive power: %vkW
		pcc    power factor  : %v
`,
				f32(data.voltage_phase) * 0.1,
				f32(data.output_current) * 0.01,
				f32(data.output_active_power) * 0.01,
				f32(data.output_reactive_power) * 0.01,
				f32(data.output_power_factor) * 0.001,
				f32(data.pcc_current) * 0.01,
				f32(data.pcc_active_power) * 0.01,
				f32(data.pcc_reactive_power) * 0.01,
				f32(data.pcc_power_factor) * 0.001,
			)
	}
	print_phase_to_n :: proc(data : PhaseToNOutput)
	{
		fmt.printf(`
		voltage              : %vV
		output current       : %vA
		output active   power: %vkW
		pcc    current       : %vA
		pcc    active   power: %vkW
`,
				f32(data.voltage_phase) * 0.1,
				f32(data.output_current) * 0.01,
				f32(data.output_active_power) * 0.01,
				f32(data.pcc_current) * 0.01,
				f32(data.pcc_active_power) * 0.01,
			)
	}
}

// 0x0500 - complete
RegistersEmergencyOutput :: struct #packed {
	validity_mask : u64be,
	// kW, * 0.01
	total_load_power_active : u16be,
	// kW, * 0.01
	total_load_power_reactive : u16be,
	// kW, * 0.01
	total_load_power_apparent : u16be,
	// Hz, * 0.01
	output_frequency : u16be,
	_ : u16be,
	_ : u16be,
	r, s, t : EmergencyPhaseOutput,
	// V, * 0.1
	output_voltage_L1N : u16be,
	// A, * 0.01
	load_current_L1N : i16be,
	// kW, * 0.01
	load_power_active_L1N : i16be,
	// V, * 0.1
	output_voltage_L2N : u16be,
	// A, * 0.01
	load_current_L2N : i16be,
	// kW, * 0.01
	load_power_active_L2N : i16be,
}

EmergencyPhaseOutput :: struct #packed {
	// V, * 0.1
	voltage_output : u16be,
	// A, * 0.01
	current_load : i16be,
	// kW, * 0.01
	power_active : i16be,
	// kW, * 0.01
	power_reactive : i16be,
	// kW, * 0.01
	power_apparent : i16be,
	// * 0.01
	load_peak_ratio : u16be,
	// V, * 0.1
	voltage_load : u16be,
	_ : u16be,
}

print_emergency_output :: proc(data : RegistersEmergencyOutput)
{
	fmt.printf(`emergency production:
	mask: %64b
	total active   power: %vkW
	total reactive power: %vkW
	total apparent power: %vkW
	output frequency    : %vHz
`,
		data.validity_mask,
		f32(data.total_load_power_active) * 0.01, // kW, * 0.01
		f32(data.total_load_power_reactive) * 0.01, // kW, * 0.01
		f32(data.total_load_power_apparent) * 0.01, // kW, * 0.01
		f32(data.output_frequency) * 0.01, // Hz, * 0.01
	)
	
	fmt.print("phase r:")
	print_phase(data.r)
	fmt.print("phase s:")
	print_phase(data.s)
	fmt.print("phase t:")
	print_phase(data.t)

	fmt.printf(`
	L1N output voltage   : %vV
	L1N load current     : %vA
	L1N load active power: %vkW
	L1N output voltage   : %vV
	L1N load current     : %vA
	L1N load active power: %vkW
`,
		f32(data.output_voltage_L1N) * 0.1, // V, * 0.1
		f32(data.load_current_L1N) * 0.01, // A, * 0.01
		f32(data.load_power_active_L1N) * 0.01, // kW, * 0.01
		f32(data.output_voltage_L2N) * 0.1, // V, * 0.1
		f32(data.load_current_L2N) * 0.01, // A, * 0.01
		f32(data.load_power_active_L2N) * 0.01, // kW, * 0.01
	)

	print_phase :: proc(data : EmergencyPhaseOutput)
	{
		fmt.printf(`
		output voltage : %vV
		load current   : %vA
		active   power : %vkW
		reactive power : %vkW
		apparent power : %vkW
		load peak ratio: %v
		load voltage   : %vV
`,
			f32(data.voltage_output) * 0.1, // V, * 0.1
			f32(data.current_load) * 0.01, // A, * 0.01
			f32(data.power_active) * 0.01, // kW, * 0.01
			f32(data.power_reactive) * 0.01, // kW, * 0.01
			f32(data.power_apparent) * 0.01, // kW, * 0.01
			f32(data.load_peak_ratio) * 0.01, // * 0.01
			f32(data.voltage_load) * 0.1, // V, * 0.1
		)
	}
}


// 0x0680
RegistersHistoricProduction :: struct #packed {
	validity_mask : u64be,
	// kwh, * 0.01
	generation_today : u32be,
	// kwh, * 0.1
	generation_total : u32be,
	// kwh, * 0.01
	load_consumption_today : u32be,
	// kwh, * 0.1
	load_consumtion_total : u32be,
}

print_historic_production :: proc(data : RegistersHistoricProduction)
{
	fmt.printf(`historic production:
	mask: %64b
	generation today      : %vkWh
	generation total      : %vkWh
	load consumption today: %vkWh
	load consumption total: %vkWh
`,
		data.validity_mask,
		f32(data.generation_today) * 0.01,
		f32(data.generation_total) * 0.1,
		f32(data.load_consumption_today) * 0.01,
		f32(data.load_consumtion_total) * 0.1,
	)
}

// 0x0580
RegistersIndividualStrings :: struct #packed {
	validity_mask : u64be,
	strings : [16]RegistersStringInfo,
}

RegistersStringInfo :: struct #packed {
	// V, * 0.1
	voltage : u16be,
	// A, * 0.01
	amperage : u16be,
	// kW, * 0.01
	power : u16be,
}

print_strings_info :: proc(data : RegistersIndividualStrings)
{
	fmt.printf(`string info:
	mask: %64b
`, data.validity_mask)
	for pv_string, si in data.strings {
		fmt.printf("\tstring#%v\n", si + 1)
		fmt.printf("\t\tvoltage : %vV\n", f32(pv_string.voltage) * 0.1)
		fmt.printf("\t\tamperage: %vA\n", f32(pv_string.amperage) * 0.01)
		fmt.printf("\t\tpower   : %vkW\n", f32(pv_string.power) * 0.01)
	}
}
