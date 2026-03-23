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

local buff = {
	__T = (nil :: any) :: buffer,
	read = function(b: buffer, cursor: number)
		local length = buffer.readu16(b, cursor)
		local freshBuffer = buffer.create(length)

		-- copy the data from the main buffer to the new buffer with an offset of 2 because of length
		buffer.copy(freshBuffer, 0, b, cursor + 2, length)

		return freshBuffer, length + 2
	end,
	write = function(data: buffer)
		local length = buffer.len(data)
		alloc(2 + length)
		buffer.writeu16(channel_state.buff, channel_state.cursor, length)
		channel_state.cursor += 2
		buffer.copy(channel_state.buff, channel_state.cursor, data, 0, length)
		channel_state.cursor += length
	end,
}

return function(): types.DataType<buffer>
	return buff
end
