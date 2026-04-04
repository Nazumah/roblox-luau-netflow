--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local buff = {
	__T = (nil :: any) :: buffer,

	read = function(b: buffer, cursor: number)
		local length = buffer.readu16(b, cursor)
		local freshBuffer = buffer.create(length)
		buffer.copy(freshBuffer, 0, b, cursor + 2, length)
		return freshBuffer, length + 2
	end,

	write = function(data: buffer)
		local length = buffer.len(data)
		alloc(2 + length)
		local c = channel_state.cursor
		buffer.writeu16(channel_state.buff, c, length)
		buffer.copy(channel_state.buff, c + 2, data, 0, length)
		channel_state.cursor = c + 2 + length
	end,
}

return function(): types.DataType<buffer>
	return buff
end
