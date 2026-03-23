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

local vec2 = {
	__T = (nil :: any) :: Vector2,

	read = function(b: buffer, cursor: number)
		return Vector2.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4)), 8
	end,

	write = function(value: Vector2)
		alloc(8)
		buffer.writef32(channel_state.buff, channel_state.cursor, value.X)
		channel_state.cursor += 4
		buffer.writef32(channel_state.buff, channel_state.cursor, value.Y)
		channel_state.cursor += 4
	end,

	length = 8,
}

return function(): types.DataType<Vector2>
	return vec2
end
