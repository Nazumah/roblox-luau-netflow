--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local vec2 = {
	__T = (nil :: any) :: Vector2,

	read = function(b: buffer, cursor: number)
		return Vector2.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4)), 8
	end,

	write = function(value: Vector2)
		alloc(8)
		local c = channel_state.cursor
		buffer.writef32(channel_state.buff, c, value.X)
		buffer.writef32(channel_state.buff, c + 4, value.Y)
		channel_state.cursor = c + 8
	end,

	length = 8,
}

return function(): types.DataType<Vector2>
	return vec2
end
