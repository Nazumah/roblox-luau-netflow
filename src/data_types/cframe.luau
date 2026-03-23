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

local cframe: types.DataType<CFrame> = {
	__T = (nil :: any) :: CFrame,

	read = function(b: buffer, cursor: number)
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		local z = buffer.readf32(b, cursor + 8)
		local rx = buffer.readf32(b, cursor + 12)
		local ry = buffer.readf32(b, cursor + 16)
		local rz = buffer.readf32(b, cursor + 20)

		return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz), 24
	end,
	write = function(value: CFrame)
		local x, y, z = value.X, value.Y, value.Z
		local rx, ry, rz = value:ToEulerAnglesXYZ()

		-- Math done, write it now
		alloc(24)
		buffer.writef32(channel_state.buff, channel_state.cursor, x)
		channel_state.cursor += 4
		buffer.writef32(channel_state.buff, channel_state.cursor, y)
		channel_state.cursor += 4
		buffer.writef32(channel_state.buff, channel_state.cursor, z)
		channel_state.cursor += 4
		buffer.writef32(channel_state.buff, channel_state.cursor, rx)
		channel_state.cursor += 4
		buffer.writef32(channel_state.buff, channel_state.cursor, ry)
		channel_state.cursor += 4
		buffer.writef32(channel_state.buff, channel_state.cursor, rz)
		channel_state.cursor += 4
	end,
}

return function(): types.DataType<CFrame>
	return cframe
end
