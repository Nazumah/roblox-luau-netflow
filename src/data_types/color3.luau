--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local color3 = {
	__T = (nil :: any) :: Color3,

	write = function(input: Color3)
		alloc(3)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, math.round(input.R * 255))
		buffer.writeu8(channel_state.buff, c + 1, math.round(input.G * 255))
		buffer.writeu8(channel_state.buff, c + 2, math.round(input.B * 255))
		channel_state.cursor = c + 3
	end,

	read = function(b: buffer, cursor: number)
		return Color3.fromRGB(buffer.readu8(b, cursor), buffer.readu8(b, cursor + 1), buffer.readu8(b, cursor + 2)), 3
	end,

	length = 3,
}

return function(): types.DataType<Color3>
	return color3
end
