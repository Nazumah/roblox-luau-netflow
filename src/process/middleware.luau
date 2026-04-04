--!native
--!optimize 2

type MiddlewareFn = (packetId: number, data: any, player: Player?) -> boolean

local incoming_middlewares: { MiddlewareFn } = {}
local outgoing_middlewares: { MiddlewareFn } = {}

local middleware = {}

function middleware.addIncoming(fn: MiddlewareFn)
	table.insert(incoming_middlewares, fn)
end

function middleware.addOutgoing(fn: MiddlewareFn)
	table.insert(outgoing_middlewares, fn)
end

function middleware.runIncoming(packetId: number, data: any, player: Player?): boolean
	for _, fn in incoming_middlewares do
		if fn(packetId, data, player) == false then
			return false
		end
	end
	return true
end

function middleware.runOutgoing(packetId: number, data: any, player: Player?): boolean
	for _, fn in outgoing_middlewares do
		if fn(packetId, data, player) == false then
			return false
		end
	end
	return true
end

return middleware
