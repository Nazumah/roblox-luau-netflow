--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local function map(keyType: types.DataType<any>, valueType: types.DataType<any>): types.DataType<{ [any]: any }>
	local key_write = keyType.write
	local key_read = keyType.read
	local value_write = valueType.write
	local value_read = valueType.read

	return {
		__T = (nil :: any) :: { [any]: any },

		read = function(b: buffer, cursor: number)
			local result = {}
			local mapCursor = cursor

			local mapLength = buffer.readu16(b, mapCursor)
			mapCursor += 2

			for _ = 1, mapLength do
				local key, keyLength = key_read(b, mapCursor)
				mapCursor += keyLength

				local value, valueLength = value_read(b, mapCursor)
				mapCursor += valueLength

				result[key] = value
			end

			return result, mapCursor - cursor
		end,

		write = function(data: any)
			-- Reserve 2 bytes for length, write placeholder
			alloc(2)
			local lengthOffset = channel_state.cursor
			channel_state.cursor += 2

			local count = 0
			for k, v in data do
				key_write(k)
				value_write(v)
				count += 1
			end

			-- Write real count back to placeholder
			buffer.writeu16(channel_state.buff, lengthOffset, count)
		end,
	}
end

return map
