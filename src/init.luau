local RunService = game:GetService("RunService")

local array = require(script.data_types.array)
local bool = require(script.data_types.bool)
local buff = require(script.data_types.buff)
local cframe = require(script.data_types.cframe)
local color3 = require(script.data_types.color3)
local client = require(script.process.client)
local define_packet = require(script.packets.define_packet)
local define_invoke = require(script.packets.define_invoke)
local float32 = require(script.data_types.float32)
local float64 = require(script.data_types.float64)
local inst = require(script.data_types.inst)
local int16 = require(script.data_types.int16)
local int32 = require(script.data_types.int32)
local int8 = require(script.data_types.int8)
local map = require(script.data_types.map)
local nothing = require(script.data_types.nothing)
local optional = require(script.data_types.optional)
local server = require(script.process.server)
local string = require(script.data_types.string)
local struct = require(script.data_types.struct)
local uint16 = require(script.data_types.uint16)
local uint32 = require(script.data_types.uint32)
local uint8 = require(script.data_types.uint8)
local unknown = require(script.data_types.unknown)
local vec2 = require(script.data_types.vec2)
local vec3 = require(script.data_types.vec3)

if RunService:IsServer() then
	server.start()
else
	client.init()
end

return table.freeze({
	define_packet = define_packet,
	define_invoke = define_invoke,

	t = {
		array = array,
		bool = bool(),
		optional = optional,
		uint8 = uint8(),
		uint16 = uint16(),
		uint32 = uint32(),
		int8 = int8(),
		int16 = int16(),
		int32 = int32(),
		float32 = float32(),
		float64 = float64(),
		cframe = cframe(),
		color3 = color3(),
		string = string(),
		vec2 = vec2(),
		vec3 = vec3(),
		buff = buff(),
		struct = struct,
		map = map,
		inst = inst(),
		unknown = unknown(),
		nothing = nothing(),
	},
})
