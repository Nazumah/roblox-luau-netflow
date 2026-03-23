--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

-- Enum: maps a finite set of strings to uint8 IDs.
-- Bandwidth: 1 byte per value vs (2 + strlen) bytes for raw string.
-- Example: enum({"Idle", "Walk", "Run", "Jump"})
--   "Jump" = 1 byte instead of 6 bytes → ~83% savings.
-- Max 255 unique values.
return function(values: { string }): types.DataType<string>
	local to_id: { [string]: number } = {}
	local to_value = table.create(#values)

	for i, v in values do
		to_id[v] = i
		to_value[i] = v
	end

	return {
		__T = (nil :: any) :: string,

		write = function(value: string)
			alloc(1)
			buffer.writeu8(channel_state.buff, channel_state.cursor, to_id[value] or 0)
			channel_state.cursor += 1
		end,

		read = function(b: buffer, cursor: number)
			return to_value[buffer.readu8(b, cursor)], 1
		end,

		length = 1,
	}
end
