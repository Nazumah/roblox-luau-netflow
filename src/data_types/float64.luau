--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local float64: types.DataType<number> = {
	__T = (nil :: any) :: number,

	write = function(value)
		alloc(8)
		buffer.writef64(channel_state.buff, channel_state.cursor, value)
		channel_state.cursor += 8
	end,

	read = function(b: buffer, cursor: number)
		return buffer.readf64(b, cursor), 8
	end,
}

return function(): types.DataType<number>
	return float64
end
