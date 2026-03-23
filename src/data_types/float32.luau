--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local float32: types.DataType<number> = {
	__T = (nil :: any) :: number,

	write = function(value: number)
		alloc(4)
		buffer.writef32(channel_state.buff, channel_state.cursor, value)
		channel_state.cursor += 4
	end,

	read = function(b: buffer, cursor: number)
		return buffer.readf32(b, cursor), 4
	end,
}

return function(): types.DataType<number>
	return float32
end
