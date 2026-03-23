--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local bool_data_type = {
	__T = (nil :: any) :: boolean,

	read = function(b: buffer, cursor: number)
		return buffer.readu8(b, cursor) == 1, 1
	end,

	length = 1,

	write = function(value)
		alloc(1)
		buffer.writeu8(channel_state.buff, channel_state.cursor, if value then 1 else 0)
		channel_state.cursor += 1
	end,
}

return function(): types.DataType<boolean>
	return bool_data_type
end
