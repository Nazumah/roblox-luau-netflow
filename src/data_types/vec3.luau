--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local vec3 = {
	__T = (nil :: any) :: vector,

	read = function(b: buffer, cursor: number)
		return vector.create(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4), buffer.readf32(b, cursor + 8)),
			12
	end,

	write = function(value: vector)
		alloc(12)
		local c = channel_state.cursor
		buffer.writef32(channel_state.buff, c, value.x)
		buffer.writef32(channel_state.buff, c + 4, value.y)
		buffer.writef32(channel_state.buff, c + 8, value.z)
		channel_state.cursor = c + 12
	end,

	length = 12,
}

return function(): types.DataType<vector>
	return vec3
end
