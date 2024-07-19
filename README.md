## Validator tool to discover, dump and display some information about sofarsolar 25~50KTLX-G3 inverters using the solarman LSW-3 wifi dongle

This tool is by no means meant for production, and is very much held together by tape, bt it might help someone.


### Compilation
1. Install [odin](http://odin-lang.org/)
2. run `odin run src -- <args>`

There are still a lot of hard coded values in `main.odin` that you may want to tinker with. Values in other files, especially if named, are sourced from standards or generally agreed upon and should not need to change.

### Commands
* `src.exe discover`:
	
	Send broadcast message to discover devices on the network.

* `src.exe dump <endpoint> <logger serial>`

	Start attempting to dump all registers of the inverter into `out2.txt`.
	Reading registers is whitelisted by start register, so this steps through every register and attempts to get 16 regs from that start location. Will only log successful reads.

* `src.exe show <endpoint> <logger serial>`

	Fetches some information (current output, history and input) from the inverter using hardcoded register addresses and displays it.

	Looks like
	```
	register#0480: output:
		mask: 100000100001100001000011000010000110000101111111
		grid frequency             : 49.98Hz
		total output active   power: 0.059999999kW
		total output reactive power: -2.46kW
		total output apparent power: 3.1599998kW
		total pcc    active   power: 0kW
		total pcc    reactive power: 0kW
		total pcc    apparent power: 0kW
		phase R:
			voltage              : 237.2V
			output current       : 4.44A
			output active   power: 0kW
			output reactive power: 0kW
			output power factor  : 0
			pcc    current       : 0A
			pcc    active   power: 0kW
			pcc    reactive power: 0kW
			pcc    power factor  : 0
		phase S:
			voltage              : 238.7V
			output current       : 4.4299998A
			output active   power: 0kW
			output reactive power: 0kW
			output power factor  : 0
			pcc    current       : 0A
			pcc    active   power: 0kW
			pcc    reactive power: 0kW
			pcc    power factor  : 0
		phase T:
			voltage              : 237.1V
			output current       : 4.4299998A
			output active   power: 0kW
			output reactive power: 0kW
			output power factor  : 0
			pcc    current       : 0A
			pcc    active   power: 0kW
			pcc    reactive power: 0kW
			pcc    power factor  : 0
	register#0680: historic production:
		mask: 111111111111111111111111
		generation today      : 3.6099999kWh
		generation total      : 164.5kWh
		load consumption today: 3.6099999kWh
		load consumption total: 164.5kWh
	register#0580: string info:
		mask: 1111111111111111
		string#1
			voltage : 572.79999V
			amperage: 0.099999994A
			power   : 0.059999999kW
		string#2
			voltage : 584.4V
			amperage: 0.02A
			power   : 0.0099999998kW
		string#3
			voltage : 554.7V
			amperage: 0.099999994A
			power   : 0.049999997kW
		string#4
			voltage : 608.2V
			amperage: 0.119999997A
			power   : 0.07kW
		string#5#
			...
	```

Copyright (C) 2024-now Rennorb
Im not going to pollute code with copyright notices
