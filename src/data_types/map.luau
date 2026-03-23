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

local function map(keyType: types.DataType<any>, valueType: types.DataType<any>): types.DataType<{ [any]: any }>
	-- Cache these functions to avoid the overhead of the index
	local key_write = keyType.write
	local value_write = valueType.write

	return {
		__T = (nil :: any) :: { [any]: any },
		read = function(b: buffer, cursor: number)
			local map = {}
			local mapCursor = cursor

			-- Read map length
			local mapLength = buffer.readu16(b, mapCursor)
			mapCursor += 2

			for _ = 1, mapLength do
				-- read key/value pairs and add them to the map
				local key, keyLength = keyType.read(b, mapCursor)
				mapCursor += keyLength

				local value, valueLength = valueType.read(b, mapCursor)
				mapCursor += valueLength

				map[key] = value
			end

			-- Return the map, alongside length, because mapCursor - cursor = size
			return map, mapCursor - cursor
		end,
		write = function(map: any)
			local count = 0
			for _ in map do
				count += 1
			end

			-- Write length
			alloc(2)
			buffer.writeu16(channel_state.buff, channel_state.cursor, count)
			channel_state.cursor += 2

			for k, v in map do
				-- Write key/value pairs
				key_write(k)
				value_write(v)
			end
		end,
	}
end

return map
