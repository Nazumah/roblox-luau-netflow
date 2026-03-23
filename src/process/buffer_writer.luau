local channel_state = require(script.Parent.channel_state)

local function alloc(amount: number)
	if channel_state.cursor + amount > channel_state.size then
		channel_state.size = math.max(channel_state.size * 2, channel_state.cursor + amount)
		local new_buff = buffer.create(channel_state.size)
		buffer.copy(new_buff, 0, channel_state.buff, 0, channel_state.cursor)
		channel_state.buff = new_buff
	end
end

local function write_packet(state, id, writer, data)
	local old_buff = channel_state.buff
	local old_cursor = channel_state.cursor
	local old_size = channel_state.size
	local old_references = channel_state.references

	channel_state.buff = state.buff
	channel_state.cursor = state.cursor
	channel_state.size = state.size
	channel_state.references = state.references

	alloc(1)
	buffer.writeu8(channel_state.buff, channel_state.cursor, id)
	channel_state.cursor += 1

	writer(data)

	state.buff = channel_state.buff
	state.cursor = channel_state.cursor
	state.size = channel_state.size
	state.references = channel_state.references

	channel_state.buff = old_buff
	channel_state.cursor = old_cursor
	channel_state.size = old_size
	channel_state.references = old_references

	return state
end

return {
	write_packet = write_packet,
}
