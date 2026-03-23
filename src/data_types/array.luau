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

--[[
	Create a new array with the given dataTypeInterface
]]
local function array<T>(value_ty: types.DataType<T>): types.DataType<{ T }>
	local val_write = value_ty.write
	local val_read = value_ty.read

	return {
		__T = (nil :: any) :: { T },

		read = function(buff: buffer, cursor: number)
			local array_length = buffer.readu16(buff, cursor)
			local array_cursor = cursor + 2

			local array = table.create(array_length)

			for i = 1, array_length do
				local item, length = val_read(buff, array_cursor)
				array[i] = item

				array_cursor += length
			end

			return array, array_cursor - cursor
		end,
		write = function(value: any)
			local length = #value
			alloc(2)
			buffer.writeu16(channel_state.buff, channel_state.cursor, length)
			channel_state.cursor += 2

			for i = 1, length do
				val_write(value[i])
			end
		end,
	}
end

return array
