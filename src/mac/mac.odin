package mac

import "core:strings"
import "core:strconv"


MacAddress :: distinct [6]u8


parse :: proc(text : string) -> (addr : MacAddress) {
	offset := 0
	for bi in 0..<6 {
		for strings.is_space(rune(text[offset])) || text[offset] == '-' || text[offset] == ':' { offset += 1 }
		oct_end := offset + 1
		for ; oct_end < len(text); oct_end += 1 {
			switch text[oct_end] {
				case '0'..='9', 'a'..='f', 'A'..='F': /*nothing*/
				case: break
			}
		}
		val, err := strconv.parse_u64_of_base(text[offset:oct_end], 16)
		addr[bi] = u8(val)
	}
	return
}