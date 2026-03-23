--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local str = {
	__T = (nil :: any) :: string,

	read = function(b: buffer, cursor: number)
		local length = buffer.readu16(b, cursor)
		return buffer.readstring(b, cursor + 2, length), length + 2
	end,

	write = function(data: string)
		local length = string.len(data)
		alloc(2 + length)
		local c = channel_state.cursor
		buffer.writeu16(channel_state.buff, c, length)
		buffer.writestring(channel_state.buff, c + 2, data)
		channel_state.cursor = c + 2 + length
	end,
}

return function(): types.DataType<string>
	return str
end
