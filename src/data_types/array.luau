--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local function array<T>(value_ty: types.DataType<T>): types.DataType<{ T }>
	local val_write = value_ty.write
	local val_read = value_ty.read

	return {
		__T = (nil :: any) :: { T },

		read = function(buff: buffer, cursor: number)
			local array_length = buffer.readu16(buff, cursor)
			local array_cursor = cursor + 2

			local result = table.create(array_length)

			for i = 1, array_length do
				local item, length = val_read(buff, array_cursor)
				result[i] = item
				array_cursor += length
			end

			return result, array_cursor - cursor
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
