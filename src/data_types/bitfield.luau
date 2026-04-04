--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

return function(count: number): types.DataType<{ boolean }>
	local byte_count = math.ceil(count / 8)

	return {
		__T = (nil :: any) :: { boolean },

		write = function(values: { boolean })
			alloc(byte_count)
			local c = channel_state.cursor
			local b = channel_state.buff
			for byte_idx = 0, byte_count - 1 do
				local byte_val = 0
				for bit = 0, 7 do
					local idx = byte_idx * 8 + bit + 1
					if idx > count then
						break
					end
					if values[idx] then
						byte_val = bit32.bor(byte_val, bit32.lshift(1, bit))
					end
				end
				buffer.writeu8(b, c + byte_idx, byte_val)
			end
			channel_state.cursor = c + byte_count
		end,

		read = function(b: buffer, cursor: number)
			local result = table.create(count)
			for byte_idx = 0, byte_count - 1 do
				local byte_val = buffer.readu8(b, cursor + byte_idx)
				for bit = 0, 7 do
					local idx = byte_idx * 8 + bit + 1
					if idx > count then
						break
					end
					result[idx] = bit32.band(byte_val, bit32.lshift(1, bit)) ~= 0
				end
			end
			return result, byte_count
		end,

		length = byte_count,
	}
end
