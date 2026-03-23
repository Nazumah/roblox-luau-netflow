--!native
--!optimize 2

local channel_state = require(script.Parent.channel_state)

local function alloc(amount: number)
	if channel_state.cursor + amount > channel_state.size then
		channel_state.size = math.max(channel_state.size * 2, channel_state.cursor + amount)
		local new_buff = buffer.create(channel_state.size)
		buffer.copy(new_buff, 0, channel_state.buff, 0, channel_state.cursor)
		channel_state.buff = new_buff
	end
end

return alloc
