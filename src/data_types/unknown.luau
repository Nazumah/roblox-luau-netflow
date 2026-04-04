--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local read_refs = require(script.Parent.Parent.process.readRefs)
local types = require(script.Parent.Parent.types)

local function unknown(): types.DataType<unknown>
	return {
		__T = (nil :: any) :: unknown,

		write = function(value: unknown)
			alloc(2)
			table.insert(channel_state.references, value)
			buffer.writeu16(channel_state.buff, channel_state.cursor, #channel_state.references)
			channel_state.cursor += 2
		end,

		read = function(b: buffer, cursor: number)
			local refs = read_refs.getAll()

			if not refs then
				return nil, 2
			end

			return refs[buffer.readu16(b, cursor)], 2
		end,
	}
end

return unknown
