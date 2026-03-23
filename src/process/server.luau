--!native
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local bandwidth = require(script.Parent.bandwidth)
local buffer_writer = require(script.Parent.buffer_writer)
local channel = require(script.Parent.channel)
local read = require(script.Parent.read)
local types = require(script.Parent.Parent.types)

local write_packet = buffer_writer.write_packet
local flush = channel.flush
local create = channel.create

local MAX_INCOMING_SIZE = 65536

local per_player_reliable: { [Player]: types.ChannelState } = {}
local per_player_unreliable: { [Player]: types.ChannelState } = {}

local globalReliable: types.ChannelState = create()
local globalUnreliable: types.ChannelState = create()

local function on_server_event(player: Player, data, references)
	if typeof(data) ~= "buffer" then
		return
	end
	if buffer.len(data) > MAX_INCOMING_SIZE then
		warn(`[NetFlow] Rejected oversized buffer from {player.Name}: {buffer.len(data)}B`)
		return
	end
	if references ~= nil and typeof(references) ~= "table" then
		return
	end
	read(data, references, player)
end

local function player_added(player)
	if not per_player_reliable[player] then
		per_player_reliable[player] = create()
	end
	if not per_player_unreliable[player] then
		per_player_unreliable[player] = create()
	end
end

local server = {}

function server.sendAllReliable(id: number, writer: (value: any) -> (), data: { [string]: any })
	globalReliable = write_packet(globalReliable, id, writer, data)
end

function server.sendAllUnreliable(id: number, writer: (value: any) -> (), data: { [string]: any })
	globalUnreliable = write_packet(globalUnreliable, id, writer, data)
end

function server.sendPlayerReliable(player: Player, id: number, writer: (value: any) -> (), data: { [string]: any })
	local state = per_player_reliable[player]
	if not state then
		return
	end
	per_player_reliable[player] = write_packet(state, id, writer, data)
end

function server.sendPlayerUnreliable(player: Player, id: number, writer: (value: any) -> (), data: { [string]: any })
	local state = per_player_unreliable[player]
	if not state then
		return
	end
	per_player_unreliable[player] = write_packet(state, id, writer, data)
end

function server.start()
	local reliableRemote = Instance.new("RemoteEvent")
	reliableRemote.Name = "NetFlowReliable"
	reliableRemote.OnServerEvent:Connect(on_server_event)
	reliableRemote.Parent = ReplicatedStorage

	local unreliableRemote = Instance.new("UnreliableRemoteEvent")
	unreliableRemote.Name = "NetFlowUnreliable"
	unreliableRemote.OnServerEvent:Connect(on_server_event)
	unreliableRemote.Parent = ReplicatedStorage

	for _, player in Players:GetPlayers() do
		player_added(player)
	end

	Players.PlayerAdded:Connect(player_added)

	Players.PlayerRemoving:Connect(function(player)
		per_player_reliable[player] = nil
		per_player_unreliable[player] = nil
	end)

	RunService.Heartbeat:Connect(function()
		if globalReliable.cursor > 0 then
			bandwidth.record_out(globalReliable.cursor)
			reliableRemote:FireAllClients(flush(globalReliable))
		end

		if globalUnreliable.cursor > 0 then
			bandwidth.record_out(globalUnreliable.cursor)
			unreliableRemote:FireAllClients(flush(globalUnreliable))
		end

		for _, player in Players:GetPlayers() do
			local reliableState = per_player_reliable[player]
			if reliableState and reliableState.cursor > 0 then
				bandwidth.record_out(reliableState.cursor)
				reliableRemote:FireClient(player, flush(reliableState))
			end

			local unreliableState = per_player_unreliable[player]
			if unreliableState and unreliableState.cursor > 0 then
				bandwidth.record_out(unreliableState.cursor)
				unreliableRemote:FireClient(player, flush(unreliableState))
			end
		end
	end)
end

return server
