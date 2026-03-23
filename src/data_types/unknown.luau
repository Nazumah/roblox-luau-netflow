local channel_state = require(script.Parent.Parent.process.channel_state)

local function alloc(amount: number)
	if channel_state.cursor + amount > channel_state.size then
		channel_state.size = math.max(channel_state.size * 2, channel_state.cursor + amount)
		local new_buff = buffer.create(channel_state.size)
		buffer.copy(new_buff, 0, channel_state.buff, 0, channel_state.cursor)
		channel_state.buff = new_buff
	end
end

local read_refs = require(script.Parent.Parent.process.readRefs)
local types = require(script.Parent.Parent.types)

local function unknown(): types.DataType<unknown>
	return {
		__T = (nil :: any) :: unknown,
		write = function(value: unknown)
			alloc(1)
			table.insert(channel_state.references, value)
			buffer.writeu8(channel_state.buff, channel_state.cursor, #channel_state.references)
			channel_state.cursor += 1
		end,

		read = function(b: buffer, cursor: number)
			local refs = read_refs.getAll()

			if not refs then
				return nil, 1
			end

			return refs[buffer.readu8(b, cursor)], 1
		end,
	}
end

return unknown
