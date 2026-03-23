--!native
--!optimize 2

--[[
	Exists so that the namespace can set the ID of the packet

	Packet shouldnt need to care about making its own ID
]]
local packet = require(script.Parent.packet)
local packet_ids = require(script.Parent.Parent.process.packet_ids)
local types = require(script.Parent.Parent.types)

local function define_packet(props: types.PacketProps<any>)
	return function(id: number)
		local pkt = packet(props, id)
		packet_ids.ref()[id] = pkt
		return pkt
	end
end

return define_packet
