--!native
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
	local reliableRemote = ReplicatedStorage:WaitForChild("NetFlowReliable")
	reliableRemote.OnClientEvent:Connect(function(receivedBuffer, ref)
		read(receivedBuffer, ref)
	end)

	local unreliableRemote = ReplicatedStorage:WaitForChild("NetFlowUnreliable")
	unreliableRemote.OnClientEvent:Connect(function(receivedBuffer, ref)
		read(receivedBuffer, ref)
	end)

	RunService.Heartbeat:Connect(function()
		if reliable.cursor > 0 then
			bandwidth.record_out(reliable.cursor)
			reliableRemote:FireServer(flush(reliable))
		end

		if unreliable.cursor > 0 then
			bandwidth.record_out(unreliable.cursor)
			unreliableRemote:FireServer(flush(unreliable))
		end
	end)
end

return client
