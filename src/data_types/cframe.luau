--!native
--!optimize 2

local alloc = require(script.Parent.Parent.process.alloc)
local channel_state = require(script.Parent.Parent.process.channel_state)
local types = require(script.Parent.Parent.types)

local cframe: types.DataType<CFrame> = {
	__T = (nil :: any) :: CFrame,

	read = function(b: buffer, cursor: number)
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		local z = buffer.readf32(b, cursor + 8)
		local rx = buffer.readf32(b, cursor + 12)
		local ry = buffer.readf32(b, cursor + 16)
		local rz = buffer.readf32(b, cursor + 20)

		return CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz), 24
	end,

	write = function(value: CFrame)
		local x, y, z = value.X, value.Y, value.Z
		local rx, ry, rz = value:ToEulerAnglesXYZ()

		alloc(24)
		local c = channel_state.cursor
		buffer.writef32(channel_state.buff, c, x)
		buffer.writef32(channel_state.buff, c + 4, y)
		buffer.writef32(channel_state.buff, c + 8, z)
		buffer.writef32(channel_state.buff, c + 12, rx)
		buffer.writef32(channel_state.buff, c + 16, ry)
		buffer.writef32(channel_state.buff, c + 20, rz)
		channel_state.cursor = c + 24
	end,
}

return function(): types.DataType<CFrame>
	return cframe
end
