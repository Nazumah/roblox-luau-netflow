--!native
--!optimize 2

local types = require(script.Parent.Parent.types)

local function create(): types.ChannelState
	return {
		cursor = 0,
		size = 256,
		references = {},
		buff = buffer.create(256),
	}
end

local function flush(channel: types.ChannelState): (buffer, { unknown }?)
	local cursor = channel.cursor
	local refs = channel.references
	local has_refs = #refs > 0

	local send_buff
	if cursor == channel.size then
		send_buff = channel.buff
		channel.buff = buffer.create(channel.size)
	else
		send_buff = buffer.create(cursor)
		buffer.copy(send_buff, 0, channel.buff, 0, cursor)
	end

	channel.cursor = 0
	if has_refs then
		channel.references = {}
	end

	return send_buff, if has_refs then refs else nil
end

return {
	flush = flush,
	create = create,
}
