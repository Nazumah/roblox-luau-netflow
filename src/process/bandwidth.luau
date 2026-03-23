--!native
--!optimize 2

local stats = {
	bytes_out = 0,
	bytes_in = 0,
	packets_out = 0,
	packets_in = 0,
}

local function record_out(bytes: number)
	stats.bytes_out += bytes
	stats.packets_out += 1
end

local function record_in(bytes: number)
	stats.bytes_in += bytes
	stats.packets_in += 1
end

-- Returns current stats and resets accumulators.
-- Call once per frame (or at any interval) to get throughput.
local function snapshot(): (number, number, number, number)
	local bo, bi, po, pi = stats.bytes_out, stats.bytes_in, stats.packets_out, stats.packets_in
	stats.bytes_out = 0
	stats.bytes_in = 0
	stats.packets_out = 0
	stats.packets_in = 0
	return bo, bi, po, pi
end

return {
	stats = stats,
	record_out = record_out,
	record_in = record_in,
	snapshot = snapshot,
}
