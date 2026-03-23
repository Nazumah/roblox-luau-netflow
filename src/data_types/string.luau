local channel_state = require(script.Parent.Parent.process.channel_state)

local function alloc(amount: number)
	if channel_state.cursor + amount > channel_state.size then
		channel_state.size = math.max(channel_state.size * 2, channel_state.cursor + amount)
		local new_buff = buffer.create(channel_state.size)
		buffer.copy(new_buff, 0, channel_state.buff, 0, channel_state.cursor)
		channel_state.buff = new_buff
	end
end

local types = require(script.Parent.Parent.types)

local str = {
	__T = (nil :: any) :: string,
	-- 2 bytes for the length, then the string

	read = function(b: buffer, cursor: number)
		local length = buffer.readu16(b, cursor)

		return buffer.readstring(b, cursor + 2, length), length + 2
	end,
	write = function(data: string)
		local length = string.len(data)
		alloc(2 + length)
		buffer.writeu16(channel_state.buff, channel_state.cursor, length)
		channel_state.cursor += 2
		buffer.writestring(channel_state.buff, channel_state.cursor, data)
		channel_state.cursor += length
	end,
}

return function(): types.DataType<string>
	return str
end
