--!strict

--[[
    
]]

export type Status = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type AsyncError = {
	error: string,
	trace: string?,
	context: string?,
	kind: string?,
	parent: AsyncError?,
	createdTick: number,
	createdTrace: string,
	extend: (self: AsyncError, options: any) -> AsyncError,
}

type _Async = {
	Status: Status,

	andThen: (
		self: _Async,
		successHandler: ((...any) -> ...any)?,
		failureHandler: ((...any) -> ...any)?
	) -> _Async,
	catch: (self: _Async, failureHandler: (...any) -> ...any) -> _Async,
	finally: (self: _Async, finallyHandler: (Status) -> ...any) -> _Async,

	tap: (self: _Async, tapHandler: (...any) -> ...any) -> _Async,
	andThenCall: (self: _Async, callback: (...any) -> any, ...any) -> _Async,
	andThenReturn: (self: _Async, ...any) -> _Async,
	finallyCall: (self: _Async, callback: (...any) -> any, ...any) -> _Async,
	finallyReturn: (self: _Async, ...any) -> _Async,

	timeout: (self: _Async, seconds: number, rejectionValue: any?) -> _Async,
	now: (self: _Async, rejectionValue: any?) -> _Async,

	cancel: (self: _Async) -> (),
	await: (self: _Async) -> (boolean, ...any),
	awaitStatus: (self: _Async) -> (Status, ...any),
	expect: (self: _Async) -> ...any,
	getStatus: (self: _Async) -> Status,

	_status: Status,
	_values: { any }?,
	_valuesLength: number,
	_thread: thread?,
	_unhandledRejection: boolean,

	_consumers: { [_Async]: boolean }?,
	_parent: _Async?,

	_queuedResolve: { any }?,
	_queuedReject: { any }?,
	_queuedFinally: { any }?,
	_cancellationHook: (() -> ())?,
}

export type Async<T...> = _Async & {
	await: (self: Async<T...>) -> (boolean, T...),
	awaitStatus: (self: Async<T...>) -> (Status, T...),
	expect: (self: Async<T...>) -> T...,
}

local Async = {
	_status = "Started" :: Status,
	_valuesLength = -1,
	_unhandledRejection = true,
}
Async.__index = Async

local Error = {}
Error.__index = Error

local ErrorKinds = {
	ExecutionError = "ExecutionError",
	AlreadyCancelled = "AlreadyCancelled",
	NotResolvedInTime = "NotResolvedInTime",
	TimedOut = "TimedOut",
}

function Error.new(options: any, parent: AsyncError?): AsyncError
	return setmetatable({
		error = tostring(options.error or "[This error has no error text.]"),
		trace = options.trace,
		context = options.context,
		kind = options.kind,
		parent = parent,
		createdTick = os.clock(),
		createdTrace = debug.traceback("", 2),
	}, Error) :: any
end

function Error.is(anything: any): boolean
	return type(anything) == "table" and getmetatable(anything) == Error
end

function Error.isKind(anything: any, kind: string): boolean
	return Error.is(anything) and anything.kind == kind
end

function Error:extend(options: any): AsyncError
	options = options or {}
	options.kind = options.kind or (self :: any).kind
	return Error.new(options, self :: any)
end

function Error:__tostring()
	local s = { string.format("-- Async.Error(%s) --", (self :: any).kind or "?") }
	local curr = self :: any
	while curr do
		table.insert(s, (curr.trace or curr.error) .. "\n" .. (curr.context or ""))
		curr = curr.parent
	end
	return table.concat(s, "\n")
end

local function pack(...)
	return select("#", ...), { ... }
end

local function isCallable(value: any): boolean
	if type(value) == "function" then
		return true
	end
	if type(value) == "table" then
		local metatable = getmetatable(value)
		if metatable and type(rawget(metatable, "__call")) == "function" then
			return true
		end
	end
	return false
end

function Async.is(obj: any): boolean
	if type(obj) ~= "table" then
		return false
	end
	local meta = getmetatable(obj)
	if meta == Async then
		return true
	end
	if meta == nil then
		return isCallable(obj.andThen)
	end
	if type(meta) == "table" then
		local index = rawget(meta :: { [any]: any }, "__index")
		if type(index) == "table" and isCallable(rawget(index :: { [any]: any }, "andThen")) then
			return true
		end
	end
	return false
end

local unhandledRejectionCallbacks = {}

function Async.onUnhandledRejection(callback: (promise: Async<...any>, ...any) -> ())
	table.insert(unhandledRejectionCallbacks, callback)
	return function()
		local idx = table.find(unhandledRejectionCallbacks, callback)
		if idx then
			table.remove(unhandledRejectionCallbacks, idx)
		end
	end
end

local function runExecutor(callback: any, ...: any)
	return xpcall(callback, function(err)
		if type(err) == "table" then
			return err
		end
		return Error.new({
			error = err,
			kind = ErrorKinds.ExecutionError,
			trace = debug.traceback(tostring(err), 2),
		})
	end, ...)
end

function Async._new<T...>(
	executor: (
		resolve: (...any) -> (),
		reject: (...any) -> (),
		onCancel: ((() -> ())?) -> boolean
	) -> (),
	parent: Async<...any>?
): Async<T...>
	local self = setmetatable({
		_status = "Started" :: Status,
		_values = nil :: { any }?,
		_valuesLength = -1,
		_thread = nil :: thread?,
		_unhandledRejection = true,
		_consumers = nil :: { [Async<...any>]: boolean }?,
		_parent = parent,
		_queuedResolve = nil :: { any }?,
		_queuedReject = nil :: { any }?,
		_queuedFinally = nil :: { any }?,
		_cancellationHook = nil :: (() -> ())?,
	}, Async)

	if parent and parent._status == "Started" then
		if not parent._consumers then
			parent._consumers = setmetatable({}, { __mode = "k" }) :: any
		end
		local consumers = parent._consumers :: any
		consumers[self] = true
	end

	local function resolve(...)
		if self._status ~= "Started" then
			return
		end
		self._status = "Resolved"
		self._valuesLength = select("#", ...)
		self._values = { ... }

		if self._queuedResolve then
			for _, callback in ipairs(self._queuedResolve) do
				task.spawn(callback, ...)
			end
			self._queuedResolve = nil
		end
		if self._queuedFinally then
			for _, callback in ipairs(self._queuedFinally) do
				task.spawn(callback, "Resolved")
			end
			self._queuedFinally = nil
		end
	end

	local function reject(...)
		if self._status ~= "Started" then
			return
		end
		self._status = "Rejected"
		self._valuesLength = select("#", ...)
		self._values = { ... }

		if self._queuedReject then
			for _, callback in ipairs(self._queuedReject) do
				task.spawn(callback, ...)
			end
			self._queuedReject = nil
		else
			local errArgs = self._values
			local errLen = self._valuesLength
			task.defer(function()
				if self._unhandledRejection then
					if #unhandledRejectionCallbacks > 0 then
						for _, cb in ipairs(unhandledRejectionCallbacks) do
							task.spawn(cb, self :: any, unpack(errArgs :: any, 1, errLen))
						end
					else
						warn("Unhandled Async Rejection:", errArgs and errArgs[1] or "nil")
					end
				end
			end)
		end
		if self._queuedFinally then
			for _, callback in ipairs(self._queuedFinally) do
				task.spawn(callback, "Rejected")
			end
			self._queuedFinally = nil
		end
	end

	local function onCancel(hook: (() -> ())?): boolean
		if hook then
			if self._status == "Cancelled" then
				task.spawn(hook)
			else
				self._cancellationHook = hook
			end
		end
		return self._status == "Cancelled"
	end

	self._thread = coroutine.create(function()
		local success, result = runExecutor(executor :: any, resolve, reject, onCancel)
		if not success then
			reject(result)
		end
	end)

	task.spawn(self._thread :: thread)

	return (self :: any) :: Async<T...>
end

function Async.new<T...>(
	executor: (
		resolve: (...any) -> (),
		reject: (...any) -> (),
		onCancel: ((() -> ())?) -> boolean
	) -> ()
): Async<T...>
	return Async._new(executor)
end

function Async.defer<T...>(
	executor: (
		resolve: (...any) -> (),
		reject: (...any) -> (),
		onCancel: ((() -> ())?) -> boolean
	) -> ()
): Async<T...>
	local promise
	promise = Async._new(function(resolve, reject, onCancel)
		local thread = task.defer(function()
			if promise and promise:getStatus() ~= "Started" then
				return
			end
			local success, result = runExecutor(executor :: any, resolve, reject, onCancel)
			if not success then
				reject(result)
			end
		end)
		onCancel(function()
			task.cancel(thread)
		end)
	end)
	return promise
end

function Async.try<T...>(callback: (...any) -> ...any, ...: any): Async<T...>
	local len, args = pack(...)
	return Async._new(function(resolve, reject)
		local results = table.pack(runExecutor(callback :: any, unpack(args, 1, len)))
		if results[1] then
			resolve(unpack(results, 2, results.n))
		else
			reject(results[2])
		end
	end)
end

function Async.promisify(callback: (...any) -> ...any): (...any) -> Async<...any>
	return function(...)
		return Async.try(callback, ...)
	end
end

function Async.resolve(...: any): Async<...any>
	local len, vals = pack(...)
	return Async._new(function(resolve)
		resolve(unpack(vals, 1, len))
	end)
end

function Async.reject(...: any): Async<...any>
	local len, vals = pack(...)
	return Async._new(function(_, reject)
		reject(unpack(vals, 1, len))
	end)
end

function Async:getStatus(): Status
	return self._status
end

function Async:cancel()
	local selfAny = self :: any
	if selfAny._status ~= "Started" then
		return
	end
	selfAny._status = "Cancelled"

	if selfAny._cancellationHook then
		task.spawn(selfAny._cancellationHook)
	end

	if selfAny._thread and coroutine.status(selfAny._thread) == "suspended" then
		task.cancel(selfAny._thread)
	end

	if selfAny._parent and selfAny._parent._status == "Started" then
		if selfAny._parent._consumers then
			selfAny._parent._consumers[self] = nil
			if next(selfAny._parent._consumers) == nil then
				selfAny._parent:cancel()
			end
		end
	end

	if selfAny._consumers then
		for consumer in pairs(selfAny._consumers) do
			consumer:cancel()
		end
	end
end

function Async:andThen(successHandler: ((...any) -> ...any)?, failureHandler: ((...any) -> ...any)?): Async<...any>
	local selfAny = self :: any
	selfAny._unhandledRejection = false

	if selfAny._status == "Cancelled" then
		local promise = Async.new(function() end)
		promise:cancel()
		return promise
	end

	return Async._new(function(resolve, reject)
		local function successCallback(...: any)
			if not successHandler then
				resolve(...)
				return
			end
			local results = table.pack(runExecutor(successHandler :: any, ...))
			if results[1] then
				local result = results[2]
				if Async.is(result) then
					result:andThen(resolve, reject)
				else
					resolve(unpack(results, 2, results.n))
				end
			else
				reject(results[2])
			end
		end

		local function failureCallback(...: any)
			if not failureHandler then
				reject(...)
				return
			end
			local results = table.pack(runExecutor(failureHandler :: any, ...))
			if results[1] then
				local result = results[2]
				if Async.is(result) then
					result:andThen(resolve, reject)
				else
					resolve(unpack(results, 2, results.n))
				end
			else
				reject(results[2])
			end
		end

		if selfAny._status == "Resolved" then
			task.spawn(successCallback, unpack(selfAny._values, 1, selfAny._valuesLength))
		elseif selfAny._status == "Rejected" then
			task.spawn(failureCallback, unpack(selfAny._values, 1, selfAny._valuesLength))
		elseif selfAny._status == "Started" then
			if not selfAny._queuedResolve then
				selfAny._queuedResolve = {}
			end
			if not selfAny._queuedReject then
				selfAny._queuedReject = {}
			end
			table.insert(selfAny._queuedResolve, successCallback)
			table.insert(selfAny._queuedReject, failureCallback)
		end
	end, self)
end

function Async:catch(failureHandler: (...any) -> ...any): Async<...any>
	return self:andThen(nil, failureHandler)
end

function Async:tap(tapHandler: (...any) -> ...any): Async<...any>
	return self:andThen(function(...: any)
		local callbackReturn = tapHandler(...)
		if Async.is(callbackReturn) then
			local length, values = pack(...)
			return (callbackReturn :: Async<...any>):andThen(function()
				return unpack(values, 1, length)
			end)
		end
		return ...
	end)
end

function Async:andThenCall(callback: (...any) -> any, ...: any): Async<...any>
	local length, values = pack(...)
	return self:andThen(function()
		return callback(unpack(values, 1, length))
	end)
end

function Async:andThenReturn(...: any): Async<...any>
	local length, values = pack(...)
	return self:andThen(function()
		return unpack(values, 1, length)
	end)
end

function Async:finally(finallyHandler: (Status) -> ...any): Async<...any>
	local selfAny = self :: any
	selfAny._unhandledRejection = false

	if selfAny._status == "Cancelled" then
		local promise = Async.new(function() end)
		promise:cancel()
		return promise
	end

	return Async._new(function(resolve, reject, onCancel)
		local handlerPromise

		onCancel(function()
			if selfAny._consumers then
				selfAny._consumers[self] = nil
				if next(selfAny._consumers) == nil then
					selfAny:cancel()
				end
			end
			if handlerPromise then
				handlerPromise:cancel()
			end
		end)

		local function finallyCallback(status: Status)
			if not finallyHandler then
				if status == "Resolved" then
					resolve(unpack(selfAny._values, 1, selfAny._valuesLength))
				else
					reject(unpack(selfAny._values, 1, selfAny._valuesLength))
				end
				return
			end

			local results = table.pack(runExecutor(finallyHandler :: any, status))
			if results[1] then
				local result = results[2]
				if Async.is(result) then
					handlerPromise = result
					result
						:finally(function(hStatus)
							if hStatus ~= "Rejected" then
								if status == "Resolved" then
									resolve(unpack(selfAny._values, 1, selfAny._valuesLength))
								else
									reject(unpack(selfAny._values, 1, selfAny._valuesLength))
								end
							end
						end)
						:catch(reject)
				else
					if status == "Resolved" then
						resolve(unpack(selfAny._values, 1, selfAny._valuesLength))
					else
						reject(unpack(selfAny._values, 1, selfAny._valuesLength))
					end
				end
			else
				reject(results[2])
			end
		end

		if selfAny._status ~= "Started" then
			task.spawn(finallyCallback, selfAny._status)
		else
			if not selfAny._queuedFinally then
				selfAny._queuedFinally = {}
			end
			table.insert(selfAny._queuedFinally, finallyCallback)
		end
	end)
end

function Async:finallyCall(callback: (...any) -> any, ...: any): Async<...any>
	local length, values = pack(...)
	return self:finally(function()
		return callback(unpack(values, 1, length))
	end)
end

function Async:finallyReturn(...: any): Async<...any>
	local length, values = pack(...)
	return self:finally(function()
		return unpack(values, 1, length)
	end)
end

function Async:awaitStatus(): (Status, ...any)
	local selfAny = self :: any
	selfAny._unhandledRejection = false

	if selfAny._status == "Started" then
		local thread = coroutine.running()
		self:finally(function()
			task.spawn(thread)
		end):catch(function() end)
		coroutine.yield()
	end

	if selfAny._status == "Resolved" then
		return selfAny._status, unpack(selfAny._values, 1, selfAny._valuesLength)
	elseif selfAny._status == "Rejected" then
		return selfAny._status, unpack(selfAny._values, 1, selfAny._valuesLength)
	end

	return selfAny._status :: Status
end

function Async:await(): (boolean, ...any)
	local results = table.pack(self:awaitStatus())
	return results[1] == "Resolved", unpack(results, 2, results.n)
end

function Async:expect(): ...any
	local results = table.pack(self:awaitStatus())
	local status = results[1]
	if status ~= "Resolved" then
		error(results[2] == nil and "Expected Async rejected with no value." or results[2], 2)
	end
	return unpack(results, 2, results.n)
end

function Async.delay(seconds: number): Async<number>
	local startTime = os.clock()
	return Async.new(function(resolve, _, onCancel)
		local thread = task.delay(seconds, function()
			resolve(os.clock() - startTime)
		end)
		onCancel(function()
			task.cancel(thread)
		end)
	end)
end

function Async:timeout(seconds: number, rejectionValue: any?): Async<...any>
	local traceback = debug.traceback(nil, 2)
	return Async.race({
		Async.delay(seconds):andThen(function()
			return Async.reject(rejectionValue == nil and Error.new({
				kind = ErrorKinds.TimedOut,
				error = "Timed out",
				context = string.format(
					"Timeout of %d seconds exceeded.\n:timeout() called at:\n\n%s",
					seconds,
					traceback
				),
			}) or rejectionValue)
		end),
		self,
	})
end

function Async:now(rejectionValue: any?): Async<...any>
	local traceback = debug.traceback(nil, 2)
	if self._status == "Resolved" then
		return self:andThen(function(...)
			return ...
		end)
	else
		return Async.reject(rejectionValue == nil and Error.new({
			kind = ErrorKinds.NotResolvedInTime,
			error = "This Async was not resolved in time for :now()",
			context = ":now() was called at:\n\n" .. traceback,
		}) or rejectionValue)
	end
end

function Async.fromEvent(event: any, predicate: ((...any) -> boolean)?): Async<...any>
	predicate = predicate or function()
		return true
	end

	return Async.new(function(resolve, reject, onCancel)
		local connection: RBXScriptConnection?
		local shouldDisconnect = false

		local function disconnect()
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end

		connection = event:Connect(function(...)
			local results = table.pack(runExecutor(predicate :: any, ...))
			local success = results[1]
			local callbackValue = results[2]

			if not success then
				disconnect()
				reject(callbackValue)
				return
			end

			if callbackValue == true then
				resolve(...)
				if connection then
					disconnect()
				else
					shouldDisconnect = true
				end
			elseif type(callbackValue) ~= "boolean" then
				reject(Error.new({
					error = "Async.fromEvent predicate should always return a boolean",
					kind = ErrorKinds.ExecutionError,
				}))
			end
		end)

		if shouldDisconnect and connection then
			disconnect()
		end
		onCancel(disconnect)
	end)
end

function Async.all(promises: { Async<...any> }): Async<{ any }>
	return Async.new(function(resolve, reject, onCancel)
		if type(promises) ~= "table" then
			error("Please pass a list of promises to Async.all", 2)
		end
		local results = {}
		local count = 0
		local done = false

		if #promises == 0 then
			resolve({} :: any)
			return
		end

		local function cancelAll()
			for _, p in ipairs(promises) do
				p:cancel()
			end
		end
		onCancel(cancelAll)

		for i, promise in ipairs(promises) do
			if not Async.is(promise) then
				error("Non-promise value passed into Async.all", 2)
			end
			promise:andThen(function(...)
				if done then
					return
				end
				count += 1
				results[i] = (...)
				if count >= #promises then
					done = true
					resolve(results)
					cancelAll()
				end
			end, function(...)
				if done then
					return
				end
				done = true
				reject(...)
				cancelAll()
			end)
		end
	end)
end

function Async.allSettled(promises: { Async<...any> }): Async<{ Status }>
	return Async.new(function(resolve, _, onCancel)
		if type(promises) ~= "table" then
			error("Please pass a list of promises to Async.allSettled", 2)
		end
		local fates = {}
		local finishedCount = 0

		if #promises == 0 then
			resolve({} :: any)
			return
		end

		onCancel(function()
			for _, promise in ipairs(promises) do
				promise:cancel()
			end
		end)

		for i, promise in ipairs(promises) do
			promise:finally(function(status: Status)
				finishedCount += 1
				fates[i] = status
				if finishedCount >= #promises then
					resolve(fates)
				end
			end)
		end
	end)
end

function Async.race(promises: { Async<...any> }): Async<...any>
	return Async.new(function(resolve, reject, onCancel)
		if type(promises) ~= "table" then
			error("Please pass a list of promises to Async.race", 2)
		end
		local done = false
		if #promises == 0 then
			resolve()
			return
		end

		local function cancelAll()
			for _, p in ipairs(promises) do
				p:cancel()
			end
		end
		onCancel(cancelAll)

		for _, promise in ipairs(promises) do
			promise:andThen(function(...)
				if done then
					return
				end
				done = true
				resolve(...)
				cancelAll()
			end, function(...)
				if done then
					return
				end
				done = true
				reject(...)
				cancelAll()
			end)
		end
	end)
end

function Async.any(promises: { Async<...any> }): Async<...any>
	return Async.new(function(resolve, reject, onCancel)
		if type(promises) ~= "table" then
			error("Please pass a list of promises to Async.any", 2)
		end
		local done = false
		local rejectedCount = 0
		if #promises == 0 then
			resolve()
			return
		end

		local function cancelAll()
			for _, p in ipairs(promises) do
				p:cancel()
			end
		end
		onCancel(cancelAll)

		for _, promise in ipairs(promises) do
			promise:andThen(function(...)
				if done then
					return
				end
				done = true
				resolve(...)
				cancelAll()
			end, function(...)
				if done then
					return
				end
				rejectedCount += 1
				if rejectedCount >= #promises then
					done = true
					reject(...)
					cancelAll()
				end
			end)
		end
	end)
end

function Async.some(promises: { Async<...any> }, count: number): Async<{ any }>
	return Async.new(function(resolve, reject, onCancel)
		if type(promises) ~= "table" then
			error("Please pass a list of promises to Async.some", 2)
		end
		local results = {}
		local resolvedCount = 0
		local rejectedCount = 0
		local done = false

		if #promises == 0 or count == 0 then
			resolve({} :: any)
			return
		end

		local function cancelAll()
			for _, p in ipairs(promises) do
				p:cancel()
			end
		end
		onCancel(cancelAll)

		for _, promise in ipairs(promises) do
			promise:andThen(function(...)
				if done then
					return
				end
				resolvedCount += 1
				results[resolvedCount] = ...

				if resolvedCount >= count then
					done = true
					resolve(results)
					cancelAll()
				end
			end, function(...)
				if done then
					return
				end
				rejectedCount += 1

				if #promises - rejectedCount < count then
					done = true
					reject(...)
					cancelAll()
				end
			end)
		end
	end)
end

function Async.each<T, U>(list: { T | Async<T> }, predicate: (value: T, index: number) -> U | Async<U>): Async<{ U }>
	return Async.new(function(resolve, reject, onCancel)
		local results = {}
		local cancelled = false
		local promisesToCancel = {}

		local function cancel()
			cancelled = true
			for _, p in ipairs(promisesToCancel) do
				p:cancel()
			end
		end
		onCancel(cancel)

		local preprocessed: { any } = {}
		for i, val in ipairs(list) do
			if Async.is(val) then
				if (val :: _Async):getStatus() == "Cancelled" then
					cancel()
					reject(Error.new({ error = "Async is cancelled", kind = ErrorKinds.AlreadyCancelled }))
					return
				elseif (val :: _Async):getStatus() == "Rejected" then
					cancel()
					local _, err = (val :: _Async):awaitStatus()
					reject(err)
					return
				end
				local chained = (val :: _Async):andThen(function(...)
					return ...
				end)
				table.insert(promisesToCancel, chained)
				preprocessed[i] = chained
			else
				preprocessed[i] = val
			end
		end

		for i, val in ipairs(preprocessed) do
			if Async.is(val) then
				local resultsPack = table.pack((val :: Async<T>):await())
				local success = resultsPack[1]
				if not success then
					cancel()
					reject(resultsPack[2])
					return
				end
				val = resultsPack[2]
			end

			if cancelled then
				return
			end
			local predicatePromise = Async.resolve(predicate((val :: any) :: T, i))
			table.insert(promisesToCancel, predicatePromise)
			local predicateResults = table.pack(predicatePromise:await())
			if not predicateResults[1] then
				cancel()
				reject(predicateResults[2])
				return
			end
			results[i] = predicateResults[2]
		end
		resolve(results)
	end)
end

function Async.fold<T, U>(
	list: { T | Async<T> },
	reducer: (accumulator: U, value: T, index: number) -> U | Async<U>,
	initialValue: U
): Async<U>
	return Async.new(function(resolve, reject, onCancel)
		local accumulator: any = Async.resolve(initialValue)
		local eachPromise = Async.each(list, function(resolvedElement: any, i: number)
			accumulator = accumulator:andThen(function(prev: any)
				return reducer(prev, resolvedElement, i)
			end)
			return accumulator
		end)

		onCancel(function()
			eachPromise:cancel()
		end)

		eachPromise:andThen(function()
			accumulator:andThen(resolve, reject)
		end, reject)
	end)
end

return table.freeze({
	new = Async.new,
	defer = Async.defer,
	try = Async.try,
	promisify = Async.promisify,
	resolve = Async.resolve,
	reject = Async.reject,
	all = Async.all,
	allSettled = Async.allSettled,
	race = Async.race,
	any = Async.any,
	some = Async.some,
	each = Async.each,
	fold = Async.fold,
	delay = Async.delay,
	fromEvent = Async.fromEvent,
	onUnhandledRejection = Async.onUnhandledRejection,
	is = Async.is,
	Error = Error,
	Status = {
		Started = "Started",
		Resolved = "Resolved",
		Rejected = "Rejected",
		Cancelled = "Cancelled",
	},
})
