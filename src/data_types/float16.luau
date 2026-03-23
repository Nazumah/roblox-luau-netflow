--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

-- Fixed-point 16-bit float with configurable scale.
-- signed=true (default): int16, range -32768/scale .. 32767/scale
-- signed=false: uint16, range 0 .. 65535/scale
--
-- Examples:
--   float16(100)       → precision 0.01, range -327.68..327.67
--   float16(10)        → precision 0.1,  range -3276.8..3276.7
--   float16(1, false)  → precision 1,    range 0..65535 (e.g. health)
return function(scale: number, signed: boolean?): types.DataType<number>
	local is_signed = if signed == nil then true else signed
	local inv_scale = 1 / scale

	if is_signed then
		return {
			__T = (nil :: any) :: number,

			write = function(value: number)
				alloc(2)
				buffer.writei16(channel_state.buff, channel_state.cursor, math.floor(value * scale + 0.5))
				channel_state.cursor += 2
			end,

			read = function(b: buffer, cursor: number)
				return buffer.readi16(b, cursor) * inv_scale, 2
			end,

			length = 2,
		}
	end

	return {
		__T = (nil :: any) :: number,

		write = function(value: number)
			alloc(2)
			buffer.writeu16(channel_state.buff, channel_state.cursor, math.floor(value * scale + 0.5))
			channel_state.cursor += 2
		end,

		read = function(b: buffer, cursor: number)
			return buffer.readu16(b, cursor) * inv_scale, 2
		end,

		length = 2,
	}
end
