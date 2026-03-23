--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local buffer_writer = require(script.Parent.buffer_writer)
local read = require(script.Parent.read)
local types = require(script.Parent.Parent.types)

local write_packet = buffer_writer.write_packet

local function onClientEvent(receivedBuffer, ref)
	read(receivedBuffer, ref)
end

local function create(): types.ChannelState
	return {
		cursor = 0,
		size = 256,
		references = {},
		buff = buffer.create(256),
	}
end

local function dump(channel: types.ChannelState): (buffer, { unknown }?)
	local cursor = channel.cursor
	if cursor == channel.size then
		local b = channel.buff
		channel.buff = buffer.create(channel.size)
		return b, if #channel.references > 0 then channel.references else nil
	else
		local dump_buff = buffer.create(cursor)
		buffer.copy(dump_buff, 0, channel.buff, 0, cursor)
		return dump_buff, if #channel.references > 0 then channel.references else nil
	end
end

local reliable: types.ChannelState = create()
local unreliable: types.ChannelState = create()

local client = {}

function client.send_reliable(id: number, writer: (value: any) -> (), data: any)
	reliable = write_packet(reliable, id, writer, data)
end

function client.send_unreliable(id: number, writer: (value: any) -> (), data: any)
	unreliable = write_packet(unreliable, id, writer, data)
end

function client.init()
	local reliableRemote = ReplicatedStorage:WaitForChild("ByteNetReliable")
	reliableRemote.OnClientEvent:Connect(onClientEvent)

	local unreliableRemote = ReplicatedStorage:WaitForChild("ByteNetUnreliable")
	unreliableRemote.OnClientEvent:Connect(onClientEvent)

	RunService.Heartbeat:Connect(function()
		if reliable.cursor > 0 then
			local b, r = dump(reliable)
			reliableRemote:FireServer(b, r)

			reliable.cursor = 0
			table.clear(reliable.references)
		end

		if unreliable.cursor > 0 then
			local b, r = dump(unreliable)
			unreliableRemote:FireServer(b, r)

			unreliable.cursor = 0
			table.clear(unreliable.references)
		end
	end)
end

return client
