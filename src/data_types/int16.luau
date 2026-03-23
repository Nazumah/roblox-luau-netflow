--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local int16 = {
	write = function(value)
		alloc(2)
		buffer.writei16(channel_state.buff, channel_state.cursor, value)
		channel_state.cursor += 2
	end,

	read = function(b: buffer, cursor: number)
		return buffer.readi16(b, cursor), 2
	end,
}

return function(): types.DataType<number>
	return int16 :: any
end
