--!optimize 2
--!strict

local Packages = script.Parent.Parent.Parent.Parent
local Async: any = if Packages:FindFirstChild("Async")
	then (require :: any)(Packages.Async)
	elseif script.Parent.Parent:FindFirstChild("Async") then (require :: any)(script.Parent.Parent.Async)
	else nil

export type Status = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type _Async = {
	getStatus: (self: _Async) -> Status,
	cancel: (self: _Async) -> (),
	finally: (self: _Async, finallyHandler: (status: Status) -> ...any) -> _Async,
}

export type Async<T...> = _Async

export type AsyncStatic = {
	Status: {
		Started: "Started",
		Resolved: "Resolved",
		Rejected: "Rejected",
		Cancelled: "Cancelled",
	},
	is: (object: any) -> boolean,
	new: <TReturn...>(
		executor: (
			resolve: (TReturn...) -> (),
			reject: (...any) -> (),
			onCancel: (abortHandler: (() -> ())?) -> boolean
		) -> ()
	) -> Async<TReturn...>,
}

return Async :: AsyncStatic?
