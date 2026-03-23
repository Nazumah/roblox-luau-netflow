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

local color3 = {
	__T = (nil :: any) :: Color3,

	write = function(input: Color3)
		alloc(3)
		buffer.writeu8(channel_state.buff, channel_state.cursor, input.R * 255)
		channel_state.cursor += 1
		buffer.writeu8(channel_state.buff, channel_state.cursor, input.G * 255)
		channel_state.cursor += 1
		buffer.writeu8(channel_state.buff, channel_state.cursor, input.B * 255)
		channel_state.cursor += 1
	end,

	read = function(b: buffer, cursor: number)
		return Color3.fromRGB(
			buffer.readu8(b, cursor),
			buffer.readu8(b, cursor + 1),
			buffer.readu8(b, cursor + 2)
		),
			3
	end,

	length = 3,
}

return function(): types.DataType<Color3>
	return color3
end
