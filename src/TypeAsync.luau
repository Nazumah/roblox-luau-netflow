--!optimize 2
--!strict

local Async: any = nil

if script.Parent:FindFirstChild("Async") then
	Async = (require :: any)(script.Parent.Async)
elseif script.Parent.Parent:FindFirstChild("Async") then
	Async = (require :: any)(script.Parent.Parent.Async)
else
	local Packages = script.Parent.Parent.Parent.Parent
	if Packages and Packages:FindFirstChild("Async") then
		Async = (require :: any)(Packages.Async)
	end
end

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
