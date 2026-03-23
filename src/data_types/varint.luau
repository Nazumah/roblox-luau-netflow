--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local varint = {
	__T = (nil :: any) :: number,

	write = function(value: number)
		alloc(5)
		local v = value
		while v >= 128 do
			buffer.writeu8(channel_state.buff, channel_state.cursor, bit32.bor(bit32.band(v, 0x7F), 0x80))
			channel_state.cursor += 1
			v = bit32.rshift(v, 7)
		end
		buffer.writeu8(channel_state.buff, channel_state.cursor, bit32.band(v, 0x7F))
		channel_state.cursor += 1
	end,

	read = function(b: buffer, cursor: number)
		local result = 0
		local shift = 0
		local bytes_read = 0
		while true do
			local byte = buffer.readu8(b, cursor + bytes_read)
			result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7F), shift))
			shift += 7
			bytes_read += 1
			if bit32.band(byte, 0x80) == 0 then
				break
			end
		end
		return result, bytes_read
	end,
}

local ZIGZAG_SHIFT = 31

local varsint = {
	__T = (nil :: any) :: number,

	write = function(value: number)
		local encoded = bit32.bxor(bit32.lshift(value, 1), bit32.arshift(value, ZIGZAG_SHIFT))
		varint.write(encoded)
	end,

	read = function(b: buffer, cursor: number)
		local encoded, bytes_read = varint.read(b, cursor)
		local decoded = bit32.bxor(bit32.rshift(encoded, 1), -bit32.band(encoded, 1))
		if decoded >= 0x80000000 then
			decoded -= 0x100000000
		end
		return decoded, bytes_read
	end,
}

return {
	unsigned = function(): types.DataType<number>
		return varint
	end,
	signed = function(): types.DataType<number>
		return varsint
	end,
}
