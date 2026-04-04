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
			local keys = {}
			local count = 0
			for k in data do
				count += 1
				table.insert(keys, k)
			end

			pcall(function()
				table.sort(keys)
			end)

			alloc(2)
			local lengthOffset = channel_state.cursor
			buffer.writeu16(channel_state.buff, lengthOffset, count)
			channel_state.cursor += 2

			for _, k in ipairs(keys) do
				key_write(k)
				value_write(data[k])
			end
		end,
	}
end

return map
