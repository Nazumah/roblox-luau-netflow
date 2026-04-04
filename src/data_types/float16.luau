--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

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
