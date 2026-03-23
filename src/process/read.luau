--!native
--!optimize 2

local bandwidth = require(script.Parent.bandwidth)
local packetIDs = require(script.Parent.packet_ids)
local readRefs = require(script.Parent.readRefs)

local ref = packetIDs.ref()
local free_thread: thread?

local function function_passer(fn, ...)
	local aquiredThread = free_thread
	free_thread = nil
	fn(...)
	free_thread = aquiredThread
end

local function yielder()
	while true do
		function_passer(coroutine.yield())
	end
end

local function run_listener(fn, ...)
	free_thread = task.spawn(free_thread or task.spawn(coroutine.create(yielder)), fn, ...)
end

local function read(incoming_buff: buffer, references: { [number]: unknown }?, player: Player?)
	local length = buffer.len(incoming_buff)
	if length == 0 then
		return
	end

	bandwidth.record_in(length)
	readRefs.set(references)

	local read_cursor = 0

	while read_cursor < length do
		local packet_id = buffer.readu8(incoming_buff, read_cursor)
		read_cursor += 1

		local packet = ref[packet_id]
		if not packet then
			warn(`[NetFlow] Unknown packet ID {packet_id}, discarding remaining {length - read_cursor} bytes`)
			break
		end

		local ok, value, value_len = pcall(packet.reader, incoming_buff, read_cursor)
		if not ok then
			warn(`[NetFlow] Deserialization error on packet {packet_id}: {value}`)
			break
		end

		if type(value_len) ~= "number" or value_len < 0 then
			warn(`[NetFlow] Invalid read length from packet {packet_id}: {value_len}`)
			break
		end

		read_cursor += value_len

		for _, listener in packet.getListeners() do
			run_listener(listener, value, player)
		end
	end
end

return read
