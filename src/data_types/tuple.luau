--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local types = require(script.Parent.Parent.types)

return function(types_list: { types.DataType<any> }): types.DataType<{ any }>
	local count = #types_list
	local fixed_size = 0
	local all_fixed = true

	for _, vt in types_list do
		if vt.length then
			fixed_size += vt.length
		else
			all_fixed = false
		end
	end

	return {
		__T = (nil :: any) :: { any },

		read = function(b: buffer, cursor: number)
			local result = table.create(count)
			local c = cursor
			for i, vt in types_list do
				local value, length = vt.read(b, c)
				result[i] = value
				c += length
			end
			return result, c - cursor
		end,

		write = function(values: { any })
			if fixed_size > 0 then
				alloc(fixed_size)
			end
			for i, vt in types_list do
				vt.write(values[i])
			end
		end,

		length = if all_fixed then fixed_size else nil,
	}
end
