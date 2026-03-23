--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local function map(keyType: types.DataType<any>, valueType: types.DataType<any>): types.DataType<{ [any]: any }>
	local key_write = keyType.write
	local value_write = valueType.write

	return {
		__T = (nil :: any) :: { [any]: any },

		read = function(b: buffer, cursor: number)
			local map = {}
			local mapCursor = cursor

			local mapLength = buffer.readu16(b, mapCursor)
			mapCursor += 2

			for _ = 1, mapLength do
				local key, keyLength = keyType.read(b, mapCursor)
				mapCursor += keyLength

				local value, valueLength = valueType.read(b, mapCursor)
				mapCursor += valueLength

				map[key] = value
			end

			return map, mapCursor - cursor
		end,

		write = function(map: any)
			local count = 0
			for _ in map do
				count += 1
			end

			alloc(2)
			buffer.writeu16(channel_state.buff, channel_state.cursor, count)
			channel_state.cursor += 2

			for k, v in map do
				key_write(k)
				value_write(v)
			end
		end,
	}
end

return map
