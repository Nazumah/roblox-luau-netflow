--!native
--!optimize 2

local freeThread: thread? = nil

local function pass(fn: (...any) -> (), ...)
	local acquiredThread = freeThread
	freeThread = nil
	fn(...)
	freeThread = acquiredThread
end

local function yielder()
	while true do
		pass(coroutine.yield())
	end
end

local function spawn(fn: (...any) -> (), ...: any)
	local t = freeThread
	if not t then
		t = coroutine.create(yielder)
		coroutine.resume(t)
	end
	freeThread = nil
	task.spawn(t, fn, ...)
end

return spawn
