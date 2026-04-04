--!native
--!optimize 2

local channel_state = require(script.Parent.channel_state)

local function write_packet(state, id, writer, data)
	channel_state.buff = state.buff
	channel_state.cursor = state.cursor
	channel_state.size = state.size
	channel_state.references = state.references

	local cursor = channel_state.cursor
	if cursor + 2 > channel_state.size then
		channel_state.size = math.max(channel_state.size * 2, cursor + 2)
		local new_buff = buffer.create(channel_state.size)
		buffer.copy(new_buff, 0, channel_state.buff, 0, cursor)
		channel_state.buff = new_buff
	end
	buffer.writeu16(channel_state.buff, cursor, id)
	channel_state.cursor = cursor + 2

	writer(data)

	state.buff = channel_state.buff
	state.cursor = channel_state.cursor
	state.size = channel_state.size
	state.references = channel_state.references

	return state
end

return {
	write_packet = write_packet,
}
