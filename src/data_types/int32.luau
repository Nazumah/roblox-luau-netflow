--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local int32 = {
	write = function(value)
		alloc(4)
		buffer.writei32(channel_state.buff, channel_state.cursor, value)
		channel_state.cursor += 4
	end,

	read = function(b: buffer, cursor: number)
		return buffer.readi32(b, cursor), 4
	end,
}

return function(): types.DataType<number>
	return int32 :: any
end
