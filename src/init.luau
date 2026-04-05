local RunService = game:GetService("RunService")

local array = require(script.data_types.array)
local bitfield = require(script.data_types.bitfield)
local bool = require(script.data_types.bool)
local buff = require(script.data_types.buff)
local cframe = require(script.data_types.cframe)
local cframe_q = require(script.data_types.cframe_q)
local color3 = require(script.data_types.color3)
local client = require(script.process.client)
local define_packet = require(script.packets.define_packet)
local define_invoke = require(script.packets.define_invoke)
local namespace = require(script.namespaces.namespace)
local enum_type = require(script.data_types.enum_type)
local float16 = require(script.data_types.float16)

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
local tuple = require(script.data_types.tuple)
local uint16 = require(script.data_types.uint16)
local uint32 = require(script.data_types.uint32)
local uint8 = require(script.data_types.uint8)
local unknown = require(script.data_types.unknown)
local varint = require(script.data_types.varint)
local vec2 = require(script.data_types.vec2)
local vec3 = require(script.data_types.vec3)
local vec3q = require(script.data_types.vec3q)
local middleware = require(script.process.middleware)

local bandwidth = require(script.process.bandwidth)

if RunService:IsServer() then
	server.start()
else
	client.init()
end

local Module = {
	define_packet = define_packet,
	define_invoke = define_invoke,
	namespace = namespace,
	middleware = middleware,
	bandwidth = bandwidth,

	t = table.freeze({
		array = array,
		map = map,
		struct = struct,
		tuple = tuple,
		optional = optional,

		auto = require(script.data_types.auto)(),

		bool = bool(),
		uint8 = uint8(),
		uint16 = uint16(),
		uint32 = uint32(),
		int8 = int8(),
		int16 = int16(),
		int32 = int32(),
		float32 = float32(),
		float64 = float64(),
		string = string(),
		string_interned = require(script.data_types.string_interned)(),
		buff = buff(),
		nothing = nothing(),
		unknown = unknown(),
		inst = inst(),

		cframe = cframe(),
		color3 = color3(),
		vec2 = vec2(),
		vec3 = vec3(),

		varint = varint.unsigned(),
		varsint = varint.signed(),
		float16 = float16,
		vec3q = vec3q,
		cframeq = cframe_q,
		enum = enum_type,
		bitfield = bitfield,
	}),
}

export type DataType<T> = {
	__T: T,
	write: (value: T) -> (),
	read: (b: buffer, cursor: number) -> (T, number),
}

type DataTypes = {
	array: <T>(elementType: DataType<T>) -> DataType<{ T }>,
	map: <K, V>(keyType: DataType<K>, valueType: DataType<V>) -> DataType<{ [K]: V }>,
	struct: <T>(fields: T) -> DataType<any>,
	tuple: (...DataType<any>) -> DataType<{ any }>,
	optional: <T>(inner: DataType<T>) -> DataType<T?>,
	auto: DataType<any>,
	bool: DataType<boolean>,
	uint8: DataType<number>,
	uint16: DataType<number>,
	uint32: DataType<number>,
	int8: DataType<number>,
	int16: DataType<number>,
	int32: DataType<number>,
	float32: DataType<number>,
	float64: DataType<number>,
	float16: (scale: number, signed: boolean?) -> DataType<number>,
	string: DataType<string>,
	string_interned: DataType<string>,
	buff: DataType<buffer>,
	nothing: DataType<nil>,
	unknown: DataType<any>,
	inst: DataType<Instance>,
	cframe: DataType<CFrame>,
	color3: DataType<Color3>,
	vec2: DataType<Vector2>,
	vec3: DataType<Vector3>,
	varint: DataType<number>,
	varsint: DataType<number>,
	vec3q: (min: number?, max: number?) -> DataType<Vector3>,
	cframeq: (posMin: number?, posMax: number?) -> DataType<CFrame>,
	enum: <T>(choices: { T }) -> DataType<T>,
	bitfield: (fields: { [string]: number }) -> DataType<{ [string]: number }>,
}

type NetFlowLib = {
	define_packet: <T>(props: { value: any, reliability: ("Reliable" | "Unreliable")?, max_per_frame: number? }) -> any,
	define_invoke: <Req, Res>(props: { request: any, response: any, reliability: ("Reliable" | "Unreliable")? }) -> any,
	namespace: (name: string) -> any,
	middleware: {
		addIncoming: (fn: (...any) -> boolean) -> (),
		addOutgoing: (fn: (...any) -> boolean) -> (),
	},
	bandwidth: {
		stats: { bytes_out: number, bytes_in: number, packets_out: number, packets_in: number },
	},
	t: DataTypes,
}

export type NetFlow_ = typeof(Module)

return (table.freeze(Module) :: any) :: NetFlowLib
