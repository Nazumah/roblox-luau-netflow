--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

-- Quantized Vector3: each axis mapped to uint16 within a configurable range.
-- 6 bytes total vs 12 bytes for float32 vec3 = 50% savings.
-- Default range: -2048..2048, resolution ≈ 0.0625 studs.
return function(min: number?, max: number?): types.DataType<vector>
	local lo = min or -2048
	local hi = max or 2048
	local range = hi - lo
	local encode_scale = 65535 / range
	local decode_scale = range / 65535

	return {
		__T = (nil :: any) :: vector,

		write = function(value: vector)
			alloc(6)
			local c = channel_state.cursor
			local b = channel_state.buff
			buffer.writeu16(b, c, math.clamp((value.x - lo) * encode_scale + 0.5, 0, 65535))
			buffer.writeu16(b, c + 2, math.clamp((value.y - lo) * encode_scale + 0.5, 0, 65535))
			buffer.writeu16(b, c + 4, math.clamp((value.z - lo) * encode_scale + 0.5, 0, 65535))
			channel_state.cursor = c + 6
		end,

		read = function(b: buffer, cursor: number)
			return vector.create(
				buffer.readu16(b, cursor) * decode_scale + lo,
				buffer.readu16(b, cursor + 2) * decode_scale + lo,
				buffer.readu16(b, cursor + 4) * decode_scale + lo
			), 6
		end,

		length = 6,
	}
end
