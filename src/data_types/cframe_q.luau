--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local PI = math.pi
local ROT_ENCODE = 32767 / PI
local ROT_DECODE = PI / 32767

-- Quantized CFrame: position (uint16 x3) + rotation (int16 x3).
-- 12 bytes total vs 24 bytes for float32 CFrame = 50% savings.
-- Position: configurable range (default -2048..2048), ~0.0625 stud resolution.
-- Rotation: full -π..π range, ~0.005° precision.
return function(posMin: number?, posMax: number?): types.DataType<CFrame>
	local lo = posMin or -2048
	local hi = posMax or 2048
	local range = hi - lo
	local pos_encode = 65535 / range
	local pos_decode = range / 65535

	return {
		__T = (nil :: any) :: CFrame,

		write = function(value: CFrame)
			alloc(12)
			local c = channel_state.cursor
			local b = channel_state.buff
			local rx, ry, rz = value:ToEulerAnglesXYZ()

			buffer.writeu16(b, c, math.clamp((value.X - lo) * pos_encode + 0.5, 0, 65535))
			buffer.writeu16(b, c + 2, math.clamp((value.Y - lo) * pos_encode + 0.5, 0, 65535))
			buffer.writeu16(b, c + 4, math.clamp((value.Z - lo) * pos_encode + 0.5, 0, 65535))
			buffer.writei16(b, c + 6, rx * ROT_ENCODE)
			buffer.writei16(b, c + 8, ry * ROT_ENCODE)
			buffer.writei16(b, c + 10, rz * ROT_ENCODE)
			channel_state.cursor = c + 12
		end,

		read = function(b: buffer, cursor: number)
			local x = buffer.readu16(b, cursor) * pos_decode + lo
			local y = buffer.readu16(b, cursor + 2) * pos_decode + lo
			local z = buffer.readu16(b, cursor + 4) * pos_decode + lo
			local rx = buffer.readi16(b, cursor + 6) * ROT_DECODE
			local ry = buffer.readi16(b, cursor + 8) * ROT_DECODE
			local rz = buffer.readi16(b, cursor + 10) * ROT_DECODE
			return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz), 12
		end,

		length = 12,
	}
end
