--!native
--!optimize 2
--!strict

local RunService = game:GetService("RunService")

local define_packet = require(script.Parent.define_packet)
local struct = require(script.Parent.Parent.data_types.struct)
local uint16 = require(script.Parent.Parent.data_types.uint16)
local types = require(script.Parent.Parent.types)
local Async = require(script.Parent.Parent.TypeAsync)

local run_context: "server" | "client" = if RunService:IsServer() then "server" else "client"

math.randomseed(os.clock())
local nextReqId = math.random(1, 10000)

type InvokeProps<Req, Res> = {
	request: types.DataType<Req>,
	response: types.DataType<Res>,
	reliability: ("Reliable" | "Unreliable")?,
}

return function<Req, Res>(props: InvokeProps<Req, Res>)
	return function(reqPacketId: number, resPacketId: number)
		local reqDataType = struct({
			reqId = uint16(),
			data = props.request,
		} :: any)

		local resDataType = struct({
			reqId = uint16(),
			data = props.response,
		} :: any)

		local reqPacket = define_packet({
			value = reqDataType,
			reliability = props.reliability,
		})(reqPacketId)

		local resPacket = define_packet({
			value = resDataType,
			reliability = props.reliability,
		})(resPacketId)

		local pendingRequests = {}

		-- Intercept responses internally
		resPacket.listen(function(packetData: any, _player: Player?)
			local reqId = packetData.reqId
			local callback = pendingRequests[reqId]
			if callback then
				callback(packetData.data)
				pendingRequests[reqId] = nil
			end
		end)

		local exported: any = {}

		if run_context == "server" then
			function exported.invokeClient(player: Player, data: Req): Async.Async<Res>
				if not Async then
					error("Async library is required for define_invoke")
				end
				return Async.new(function(resolve, _, onCancel)
					nextReqId = nextReqId % 65534 + 1
					local reqId = nextReqId
					pendingRequests[reqId] = resolve

					onCancel(function()
						pendingRequests[reqId] = nil
					end)

					reqPacket.sendTo({
						reqId = reqId,
						data = data,
					}, player)
				end)
			end

			function exported.setCallback(callback: (player: Player, data: Req) -> Res)
				reqPacket.listen(function(packetData, player)
					local res = callback(player, packetData.data)
					resPacket.sendTo({
						reqId = packetData.reqId,
						data = res,
					}, player)
				end)
			end
		elseif run_context == "client" then
			function exported.invokeServer(data: Req): Async.Async<Res>
				if not Async then
					error("Async library is required for define_invoke")
				end
				return Async.new(function(resolve, _, onCancel)
					nextReqId = nextReqId % 65534 + 1
					local reqId = nextReqId
					pendingRequests[reqId] = resolve

					onCancel(function()
						pendingRequests[reqId] = nil
					end)

					reqPacket.send({
						reqId = reqId,
						data = data,
					})
				end)
			end

			function exported.setCallback(callback: (data: Req) -> Res)
				reqPacket.listen(function(packetData)
					local res = callback(packetData.data)
					resPacket.send({
						reqId = packetData.reqId,
						data = res,
					})
				end)
			end
		end

		return exported
	end
end
