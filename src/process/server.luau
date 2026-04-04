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
local MAX_REFERENCES = 64

local per_player_reliable: { [Player]: types.ChannelState } = {}
local per_player_unreliable: { [Player]: types.ChannelState } = {}

local dirty_reliable: { [Player]: boolean } = {}
local dirty_unreliable: { [Player]: boolean } = {}

local globalReliable: types.ChannelState = create()
local globalUnreliable: types.ChannelState = create()

local function on_server_event(player: Player, data: any, references: any)
	if typeof(data) ~= "buffer" then
		return
	end
	if buffer.len(data) > MAX_INCOMING_SIZE then
		return
	end
	if references ~= nil then
		if typeof(references) ~= "table" then
			return
		end
		local count = 0
		for _ in references do
			count += 1
			if count > MAX_REFERENCES then
				return
			end
		end
	end
	read(data, references, player)
end

local server = {}

function server.sendAllReliable(id: number, writer: (state: any, value: any) -> (), data: { [string]: any })
	globalReliable = write_packet(globalReliable, id, writer, data)
end

function server.sendAllUnreliable(id: number, writer: (state: any, value: any) -> (), data: { [string]: any })
	globalUnreliable = write_packet(globalUnreliable, id, writer, data)
end

function server.sendPlayerReliable(
	player: Player,
	id: number,
	writer: (state: any, value: any) -> (),
	data: { [string]: any }
)
	local state = per_player_reliable[player]
	if not state then
		return
	end
	dirty_reliable[player] = true
	per_player_reliable[player] = write_packet(state, id, writer, data)
end

function server.sendPlayerUnreliable(
	player: Player,
	id: number,
	writer: (state: any, value: any) -> (),
	data: { [string]: any }
)
	local state = per_player_unreliable[player]
	if not state then
		return
	end
	dirty_unreliable[player] = true
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

	Players.PlayerAdded:Connect(function(player)
		per_player_reliable[player] = create()
		per_player_unreliable[player] = create()
	end)

	Players.PlayerRemoving:Connect(function(player)
		per_player_reliable[player] = nil
		per_player_unreliable[player] = nil
		dirty_reliable[player] = nil
		dirty_unreliable[player] = nil
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

		for player in dirty_reliable do
			local state = per_player_reliable[player]
			if state and state.cursor > 0 then
				bandwidth.record_out(state.cursor)
				reliableRemote:FireClient(player, flush(state))
			end
		end
		table.clear(dirty_reliable)

		for player in dirty_unreliable do
			local state = per_player_unreliable[player]
			if state and state.cursor > 0 then
				bandwidth.record_out(state.cursor)
				unreliableRemote:FireClient(player, flush(state))
			end
		end
		table.clear(dirty_unreliable)
	end)
end

return server
