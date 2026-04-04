--!native
--!optimize 2

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local types = require(script.Parent.Parent.types)
local client = require(script.Parent.Parent.process.client)
local server = require(script.Parent.Parent.process.server)

local run_context: "server" | "client" = if RunService:IsServer() then "server" else "client"

local current_frame = 0
RunService.Heartbeat:Connect(function()
	current_frame += 1
end)

return function(props: types.PacketProps<types.DataType<any>>, id: number)
	local reliabilityType = props.reliability or "Reliable"
	local max_per_frame = props.max_per_frame
	local listeners = {}

	local serverSendFunction = if reliabilityType == "Reliable"
		then server.sendPlayerReliable
		else server.sendPlayerUnreliable

	local serverSendAllFunction = if reliabilityType == "Reliable"
		then server.sendAllReliable
		else server.sendAllUnreliable

	local clientSendFunction = if reliabilityType == "Reliable"
		then client.send_reliable
		else client.send_unreliable

	local writer = props.value.write
	
	local last_reset_frame = 0
	local frame_sends = 0

	local function check_rate(): boolean
		if not max_per_frame then
			return true
		end
		if current_frame ~= last_reset_frame then
			frame_sends = 0
			last_reset_frame = current_frame
		end
		if frame_sends >= max_per_frame then
			return false
		end
		frame_sends += 1
		return true
	end

	local exported = {}

	setmetatable(exported, {
		__index = function(_self, index)
			if
				(index == "sendTo" or index == "sendToAllExcept" or index == "sendToAll")
				and run_context == "client"
			then
				error("[NetFlow] sendTo/sendToAllExcept/sendToAll are server-only APIs")
			elseif index == "send" and run_context == "server" then
				error("[NetFlow] send is a client-only API")
			end
		end,
	})

	exported.reader = props.value.read

	if run_context == "server" then
		function exported.sendToList(data, players: { Player })
			if not check_rate() then
				return
			end
			for _, player in players do
				serverSendFunction(player, id, writer, data)
			end
		end

		function exported.sendTo(data, player: Player)
			if not check_rate() then
				return
			end
			serverSendFunction(player, id, writer, data)
		end

		function exported.sendToAllExcept(data, except: Player)
			if not check_rate() then
				return
			end
			for _, player: Player in Players:GetPlayers() do
				if player ~= except then
					serverSendFunction(player, id, writer, data)
				end
			end
		end

		function exported.sendToAll(data)
			if not check_rate() then
				return
			end
			serverSendAllFunction(id, writer, data)
		end
	elseif run_context == "client" then
		function exported.send(data)
			if not check_rate() then
				return
			end
			clientSendFunction(id, writer, data)
		end
	end

	function exported.wait()
		local runningThread = coroutine.running()
		local fn
		fn = function(data, player)
			local idx = table.find(listeners, fn)
			if idx then
				table.remove(listeners, idx)
			end
			task.spawn(runningThread, data, player)
		end
		table.insert(listeners, fn)
		return coroutine.yield()
	end

	function exported.once(callback)
		local fn
		fn = function(data, player)
			local idx = table.find(listeners, fn)
			if idx then
				table.remove(listeners, idx)
			end
			callback(data, player)
		end
		table.insert(listeners, fn)
		return function()
			local idx = table.find(listeners, fn)
			if idx then
				table.remove(listeners, idx)
			end
		end
	end

	function exported.listen(callback)
		table.insert(listeners, callback)
		return function()
			local idx = table.find(listeners, callback)
			if idx then
				table.remove(listeners, idx)
			end
		end
	end

	function exported.getListeners()
		return listeners
	end

	return exported
end
