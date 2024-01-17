package sofarsolar_25_50KTLX_G3

import "core:fmt"

print :: proc{ print_historic_production, print_strings_info, print_output }

// 0x0480 - done 
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
	l1, l2, l3 : PhaseToNOutput,
	// V, * 0.1  bewtween R/S
	voltage_line_l1 : u16be,
	// V, * 0.1  bewtween S/T
	voltage_line_l2 : u16be,
	// V, * 0.1  bewtween T/R
	voltage_line_l3 : u16be,
	// *0.001
	total_power_factor : i16be,
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
		u64(data.validity_mask),
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

	fmt.print(`	active power external: %vkW
	total system load    : %vkW
`,
	f32(data.active_power_pv_external) * 0.01,
	f32(data.total_active_power_load_system) * 0.01,
)

	fmt.print("\tphase 1 to N:")
	print_phase_to_n(data.l1)
	fmt.print("\tphase 2 to N:")
	print_phase_to_n(data.l2)
	fmt.print("\tphase 3 to N:")
	print_phase_to_n(data.l3)


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
