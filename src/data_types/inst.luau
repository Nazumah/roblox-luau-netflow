--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local readRefs = require(script.Parent.Parent.process.readRefs)
local types = require(script.Parent.Parent.types)

return function(): types.DataType<Instance?>
	return {
		__T = (nil :: any) :: Instance?,

		write = function(value)
			alloc(1)
			table.insert(channel_state.references, value)
			buffer.writeu8(channel_state.buff, channel_state.cursor, #channel_state.references)
			channel_state.cursor += 1
		end,

		read = function(b: buffer, cursor: number)
			local refs = readRefs.getAll()

			if not refs then
				return nil, 1
			end

			local ref = refs[buffer.readu8(b, cursor)]

			if typeof(ref) == "Instance" then
				return ref, 1
			else
				return nil, 1
			end
		end,
	}
end
