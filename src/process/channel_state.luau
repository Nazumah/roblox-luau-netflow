--!native
--!optimize 2

local types = require(script.Parent.Parent.types)

local channel_state: types.ChannelState = {
	buff = buffer.create(0),
	references = {},
	cursor = 0,
	size = 0,
}

return channel_state
