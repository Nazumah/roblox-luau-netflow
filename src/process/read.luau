--!native
--!optimize 2

local bandwidth = require(script.Parent.bandwidth)
local packetIDs = require(script.Parent.packet_ids)
local readRefs = require(script.Parent.readRefs)
local freeThread = require(script.Parent.freeThread)
local middleware = require(script.Parent.middleware)

local ref = packetIDs.ref()

local function run_listener(fn, ...)
	freeThread(fn, ...)
end

local function read(incoming_buff: buffer, references: { [number]: unknown }?, player: Player?)
	local length = buffer.len(incoming_buff)
	if length == 0 then
		return
	end

	bandwidth.record_in(length)
	readRefs.set(references)

	local read_cursor = 0

	while read_cursor + 2 <= length do
		local packet_id = buffer.readu16(incoming_buff, read_cursor)
		read_cursor += 2

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

		if type(value_len) ~= "number" or value_len < 0 or read_cursor + value_len > length then
			warn(`[NetFlow] Invalid read length from packet {packet_id}: {value_len}`)
			break
		end

		read_cursor += value_len

		if middleware.runIncoming(packet_id, value, player) then
			local listeners = packet.getListeners()
			for _, listener in table.clone(listeners) do
				run_listener(listener, value, player)
			end
		end
	end
end

return read
