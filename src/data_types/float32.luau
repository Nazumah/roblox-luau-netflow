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
