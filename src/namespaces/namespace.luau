--!native
--!optimize 2

local define_packet = require(script.Parent.Parent.packets.define_packet)
local define_invoke = require(script.Parent.Parent.packets.define_invoke)

local function hash_string(str: string): number
	local hash = 2166136261
	for i = 1, #str do
		hash = bit32.bxor(hash, string.byte(str, i))
		hash = bit32.band(hash * 16777619, 0xFFFFFFFF)
	end
	return bit32.band(hash, 0xFFFF)
end

local function create_namespace(namespaceName: string)
	local self = {}

	setmetatable(self, {
		__call = function(_, packetName: string, props: any)
			local full_name = namespaceName .. "/" .. packetName

			if props.request and props.response then
				local req_id = hash_string(full_name .. "_req")
				local res_id = hash_string(full_name .. "_res")
				return define_invoke(props)(req_id, res_id)
			else
				local id = hash_string(full_name)
				return define_packet(props)(id)
			end
		end,
	})

	return self
end

return create_namespace
