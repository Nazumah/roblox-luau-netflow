--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local types = require(script.Parent.Parent.types)

return function<T, V>(input: T & {
	[string]: types.DataType<V>,
}): types.DataType<T>
	local keys = {}
	for key in input :: any do
		table.insert(keys, key)
	end
	table.sort(keys)

	local count = #keys
	local index_value_type_pairs = table.create(count)
	local index_key_pairs = table.create(count)

	local fixed_size = 0
	local all_fixed = true

	for i, key in ipairs(keys) do
		local vt = (input :: any)[key]
		index_value_type_pairs[i] = vt
		index_key_pairs[i] = key
		if vt.length then
			fixed_size += vt.length
		else
			all_fixed = false
		end
	end

	return {
		__T = (nil :: any) :: T,

		read = function(b, cursor)
			local constructed = table.create(count)
			local struct_cursor = cursor

			for index, value_type in index_value_type_pairs do
				local value, length = value_type.read(b, struct_cursor)
				constructed[index_key_pairs[index]] = value
				struct_cursor += length
			end

			return constructed, struct_cursor - cursor
		end,

		write = function(struct_value)
			if fixed_size > 0 then
				alloc(fixed_size)
			end
			for index, value_type in index_value_type_pairs do
				value_type.write(struct_value[index_key_pairs[index]])
			end
		end,

		length = if all_fixed then fixed_size else nil,
	}
end
