--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local function optional<T>(value_type: types.DataType<T>): types.DataType<T?>
	local value_read = value_type.read
	local value_write = value_type.write

	return {
		read = function(b: buffer, cursor: number)
			if buffer.readu8(b, cursor) == 0 then
				return nil, 1
			else
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
