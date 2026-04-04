--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local uint8 = {
	write = function(value)
		alloc(1)
		buffer.writeu8(channel_state.buff, channel_state.cursor, value)
		channel_state.cursor += 1
	end,

	read = function(b: buffer, cursor: number)
		return buffer.readu8(b, cursor), 1
	end,
}

return function(): types.DataType<number>
	return uint8 :: any
end
