--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local read_refs = require(script.Parent.Parent.process.readRefs)
local types = require(script.Parent.Parent.types)

local function string_interned(): types.DataType<string>
	return {
		__T = (nil :: any) :: string,

		write = function(val: string)
			local refs = channel_state.references
			local idx
			for i, v in refs do
				if v == val then
					idx = i
					break
				end
			end

			if not idx then
				table.insert(refs, val)
				idx = #refs
			end

			alloc(2)
			buffer.writeu16(channel_state.buff, channel_state.cursor, idx)
			channel_state.cursor += 2
		end,

		read = function(b: buffer, cursor: number)
			local refs = read_refs.getAll()
			if not refs then
				return "", 2
			end

			local idx = buffer.readu16(b, cursor)
			local val = refs[idx]

			if type(val) == "string" then
				return val, 2
			end
			return "", 2
		end,
	}
end

return string_interned
