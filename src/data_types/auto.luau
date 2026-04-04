--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local read_refs = require(script.Parent.Parent.process.readRefs)
local types = require(script.Parent.Parent.types)

local function write_auto(value: any)
	local t = typeof(value)
	if t == "nil" then
		alloc(1)
		buffer.writeu8(channel_state.buff, channel_state.cursor, 0)
		channel_state.cursor += 1
	elseif t == "boolean" then
		alloc(1)
		buffer.writeu8(channel_state.buff, channel_state.cursor, if value then 2 else 1)
		channel_state.cursor += 1
	elseif t == "number" then
		alloc(9)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 3)
		buffer.writef64(channel_state.buff, c + 1, value)
		channel_state.cursor = c + 9
	elseif t == "string" then
		local len = #value
		alloc(3 + len)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 4)
		buffer.writeu16(channel_state.buff, c + 1, len)
		buffer.writestring(channel_state.buff, c + 3, value)
		channel_state.cursor = c + 3 + len
	elseif t == "Vector2" then
		alloc(9)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 5)
		buffer.writef32(channel_state.buff, c + 1, value.X)
		buffer.writef32(channel_state.buff, c + 5, value.Y)
		channel_state.cursor = c + 9
	elseif t == "Vector3" then
		alloc(13)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 6)
		buffer.writef32(channel_state.buff, c + 1, value.X)
		buffer.writef32(channel_state.buff, c + 5, value.Y)
		buffer.writef32(channel_state.buff, c + 9, value.Z)
		channel_state.cursor = c + 13
	elseif t == "CFrame" then
		alloc(25)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 7)
		local pos = value.Position
		local ax, ay, az = value:ToEulerAnglesXYZ()
		buffer.writef32(channel_state.buff, c + 1, pos.X)
		buffer.writef32(channel_state.buff, c + 5, pos.Y)
		buffer.writef32(channel_state.buff, c + 9, pos.Z)
		buffer.writef32(channel_state.buff, c + 13, ax)
		buffer.writef32(channel_state.buff, c + 17, ay)
		buffer.writef32(channel_state.buff, c + 21, az)
		channel_state.cursor = c + 25
	elseif t == "Color3" then
		alloc(4)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 8)
		buffer.writeu8(channel_state.buff, c + 1, math.round(value.R * 255))
		buffer.writeu8(channel_state.buff, c + 2, math.round(value.G * 255))
		buffer.writeu8(channel_state.buff, c + 3, math.round(value.B * 255))
		channel_state.cursor = c + 4
	elseif t == "table" then
		local count = 0
		for _ in value do
			count += 1
		end
		alloc(3)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 9)
		buffer.writeu16(channel_state.buff, c + 1, count)
		channel_state.cursor = c + 3
		for k, v in value do
			write_auto(k)
			write_auto(v)
		end
	else
		alloc(3)
		local c = channel_state.cursor
		buffer.writeu8(channel_state.buff, c, 10)
		table.insert(channel_state.references, value)
		buffer.writeu16(channel_state.buff, c + 1, #channel_state.references)
		channel_state.cursor = c + 3
	end
end

local function read_auto(b: buffer, cursor: number): (any, number)
	local start_cursor = cursor
	local tag = buffer.readu8(b, cursor)
	cursor += 1

	if tag == 0 then
		return nil, cursor - start_cursor
	elseif tag == 1 then
		return false, cursor - start_cursor
	elseif tag == 2 then
		return true, cursor - start_cursor
	elseif tag == 3 then
		local val = buffer.readf64(b, cursor)
		return val, cursor + 8 - start_cursor
	elseif tag == 4 then
		local len = buffer.readu16(b, cursor)
		local val = buffer.readstring(b, cursor + 2, len)
		return val, cursor + 2 + len - start_cursor
	elseif tag == 5 then
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		return Vector2.new(x, y), cursor + 8 - start_cursor
	elseif tag == 6 then
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		local z = buffer.readf32(b, cursor + 8)
		return Vector3.new(x, y, z), cursor + 12 - start_cursor
	elseif tag == 7 then
		local px = buffer.readf32(b, cursor)
		local py = buffer.readf32(b, cursor + 4)
		local pz = buffer.readf32(b, cursor + 8)
		local ax = buffer.readf32(b, cursor + 12)
		local ay = buffer.readf32(b, cursor + 16)
		local az = buffer.readf32(b, cursor + 20)
		return CFrame.new(Vector3.new(px, py, pz)) * CFrame.fromEulerAnglesXYZ(ax, ay, az), cursor + 24 - start_cursor
	elseif tag == 8 then
		local r = buffer.readu8(b, cursor)
		local g = buffer.readu8(b, cursor + 1)
		local bb = buffer.readu8(b, cursor + 2)
		return Color3.fromRGB(r, g, bb), cursor + 3 - start_cursor
	elseif tag == 9 then
		local count = buffer.readu16(b, cursor)
		cursor += 2
		local map = {}
		for _ = 1, count do
			local k, read_len_k = read_auto(b, cursor)
			cursor += read_len_k
			local v, read_len_v = read_auto(b, cursor)
			cursor += read_len_v
			map[k] = v
		end
		return map, cursor - start_cursor
	elseif tag == 10 then
		local refs = read_refs.getAll()
		local idx = buffer.readu16(b, cursor)
		local val = if refs then refs[idx] else nil
		return val, cursor + 2 - start_cursor
	else
		return nil, 1
	end
end

local auto_data_type = {
	__T = (nil :: any) :: any,
	write = write_auto,
	read = read_auto,
}

return function(): types.DataType<any>
	return auto_data_type
end
