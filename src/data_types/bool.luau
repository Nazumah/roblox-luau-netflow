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

local bool_modifier = {
	[1] = true,
	[0] = false,
}
local bool_modifier2 = {
	[true] = 1,
	[false] = 0,
}

local bool_data_type = {
	__T = (nil :: any) :: boolean,

	--[[
		1 = true
		0 = false
		
		Write and read based off a uint8
	]]
	read = function(b: buffer, cursor: number)
		return bool_modifier[buffer.readu8(b, cursor)], 1
	end,

	length = 1,

	write = function(value)
		alloc(1)
		buffer.writeu8(channel_state.buff, channel_state.cursor, bool_modifier2[value])
		channel_state.cursor += 1
	end,
}

local function bool(): types.DataType<boolean>
	return bool_data_type
end

return bool
