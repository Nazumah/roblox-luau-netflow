local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local function alloc(amount: number)
	if channel_state.cursor + amount > channel_state.size then
		channel_state.size = math.max(channel_state.size * 2, channel_state.cursor + amount)
		local new_buff = buffer.create(channel_state.size)
		buffer.copy(new_buff, 0, channel_state.buff, 0, channel_state.cursor)
		channel_state.buff = new_buff
	end
end

local function optional<T>(value_type: types.DataType<T>): types.DataType<T?>
	local value_read = value_type.read
	local value_write = value_type.write

	return {
		--[[
			first byte is a boolean, if it's true, the next bytes are the value of valueType
			if it's false, its length of 1 cuz only 1 boolean
		]]

		read = function(b: buffer, cursor: number)
			if buffer.readu8(b, cursor) == 0 then
				-- doesn't exist
				return nil, 1
			else
				-- exists, read the value
				local item, length = value_read(b, cursor + 1)
				return item, length + 1
			end
		end,

		write = function(value: any)
			local exists = value ~= nil
			alloc(1)
			buffer.writeu8(channel_state.buff, channel_state.cursor, if exists then 1 else 0)
			channel_state.cursor += 1
			if exists then
				value_write(value)
			end
		end,
	}
end

return optional
