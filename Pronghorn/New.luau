--!strict
--!optimize 2
--!native
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

const New = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Types
export type Callback<T...> = (T...) -> ()
export type Connection = {Disconnect: (self: Connection) -> ()}
export type Event<T...> = {
	Fire: (self: Event<T...>, T...) -> ();
	Connect: (self: Event<T...>, callback: Callback<T...>) -> Connection;
	Once: (self: Event<T...>, callback: Callback<T...>) -> Connection;
	Wait: (self: Event<T...>, timeout: number?) -> (boolean, T...);
	DisconnectAll: (self: Event<T...>) -> ();
}
export type TrackedVariable<T> = {
	Get: (self: TrackedVariable<T>) -> T;
	Set: (self: TrackedVariable<T>, value: T) -> ();
	Connect: (self: TrackedVariable<T>, callback: Callback<T, T>) -> Connection;
	Once: (self: TrackedVariable<T>, callback: Callback<T, T>) -> Connection;
	Wait: (self: TrackedVariable<T>, timeout: number?) -> (boolean, T, T);
	WaitFor: (self: TrackedVariable<T>, value: T, timeout: number?) -> (boolean, T?);
	DisconnectAll: (self: TrackedVariable<T>) -> ();
}

-- Constants
const QUEUED_EVENT_QUEUE_SIZE = 256

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Parents all children to an `Instance`.
--- @param parent -- The new parent `Instance` of the children.
--- @param children? -- The list of `Instances` to be parented.
function New.Children(parent: Instance, children: {Instance}?): ()
	if children then
		for _, child in children do
			if typeof(child) == "Instance" then
				child.Parent = parent
			end
		end
	end
end

--- Creates and returns an `Event`.
--- @return Event<...any> -- The new `Event`.
function New.Event(): Event<...any>
	const callbacks: {Callback<...any>} = {}
	const waiting: {Callback<...any> | thread} = {}

	const actions: Event<...any> = {
		Fire = function(self: Event<...any>, ...: any): ()
			const currentlyWaiting = table.clone(waiting)
			table.clear(waiting)
			for _, callback in table.clone(callbacks) do
				task.spawn(callback, ...)
			end
			for _, callback in currentlyWaiting do
				if typeof(callback) == "thread" then
					if coroutine.status(callback) ~= "suspended" then continue end
					task.spawn(callback, true, ...)
				else
					task.spawn(callback, ...)
				end
			end
		end;

		Connect = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(callbacks, callback)
			return {Disconnect = function(): ()
				const index = table.find(callbacks, callback)
				if index then
					table.remove(callbacks, index)
				end
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function(): ()
				const index = table.find(waiting, callback)
				if index then
					table.remove(waiting, index)
				end
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): (boolean, ...any)
			const co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					const index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			const returns = {coroutine.yield()}
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return table.unpack(returns)
		end;

		DisconnectAll = function(self: Event<...any>): ()
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" and coroutine.status(callback) == "suspended" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	return table.freeze(actions) :: Event<...any>
end

--- Creates and returns a `QueuedEvent`.
--- @param nameHint? -- The name of the `QueuedEvent` for debugging.
--- @param queueSize? -- The queue size of the `QueuedEvent`.
--- @return Event<...any> -- The new `QueuedEvent`.
function New.QueuedEvent(nameHint: string?, queueSize: number?): Event<...any>
	const queueSize = queueSize or QUEUED_EVENT_QUEUE_SIZE

	const callbacks: {Callback<...any>} = {}
	const waiting: {Callback<...any> | thread} = {}
	local queueCount = 0
	const queuedEventInvocations: {{any}} = {}

	const function resumeQueuedEventInvocations(self: Event<...any>): {any}?
		const firstInvocation = queuedEventInvocations[1]

		if callbacks[1] or waiting[1] then
			for _, invocation in queuedEventInvocations do
				self:Fire(table.unpack(invocation))
			end
		end

		table.clear(queuedEventInvocations)
		queueCount = 0

		return firstInvocation
	end

	const actions: Event<...any> = {
		Fire = function(self: Event<...any>, ...: any): ()
			if not callbacks[1] and not waiting[1] then
				if queueCount >= queueSize then
					task.spawn(error, `QueuedEvent invocation queue exhausted{if nameHint then ` for "{nameHint}"` else ""}; did you forget to connect to it?`, 0)
				end
				queueCount += 1
				table.insert(queuedEventInvocations, {...})
			else
				const currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in table.clone(callbacks) do
					task.spawn(callback, ...)
				end
				for _, callback in currentlyWaiting do
					if typeof(callback) == "thread" then
						if coroutine.status(callback) ~= "suspended" then continue end
						task.spawn(callback, true, ...)
					else
						task.spawn(callback, ...)
					end
				end
			end
		end;

		Connect = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(callbacks, callback)
			resumeQueuedEventInvocations(self)
			return {Disconnect = function(): ()
				const index = table.find(callbacks, callback)
				if index then
					table.remove(callbacks, index)
				end
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			resumeQueuedEventInvocations(self)
			return {Disconnect = function(): ()
				const index = table.find(waiting, callback)
				if index then
					table.remove(waiting, index)
				end
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): (boolean, ...any)
			const queuedInvocation = resumeQueuedEventInvocations(self)
			if queuedInvocation then
				return true, table.unpack(queuedInvocation)
			end
			const co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					const index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			const returns = {coroutine.yield()}
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return table.unpack(returns)
		end;

		DisconnectAll = function(self: Event<...any>): ()
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" and coroutine.status(callback) == "suspended" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	return table.freeze(actions) :: Event<...any>
end

--- Creates and returns a `TrackedVariable`.
--- @param variable -- The initial value of the `TrackedVariable`.
--- @return TrackedVariable<T> -- The new `TrackedVariable`.
function New.TrackedVariable<T>(variable: T): TrackedVariable<T>
	const callbacks: {Callback<T, T>} = {}
	const waiting: {Callback<T, T> | thread} = {}

	const actions: TrackedVariable<T> = {
		Get = function(self: TrackedVariable<T>): T
			return variable
		end;

		Set = function(self: TrackedVariable<T>, newValue: T): ()
			if variable ~= newValue then
				const oldValue = variable
				variable = newValue
				const currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in table.clone(callbacks) do
					task.spawn(callback, oldValue, newValue)
				end
				for _, callback in currentlyWaiting do
					if typeof(callback) == "thread" then
						if coroutine.status(callback) ~= "suspended" then continue end
						task.spawn(callback, true, oldValue, newValue)
					else
						task.spawn(callback, oldValue, newValue)
					end
				end
			end
		end;

		Connect = function(self: TrackedVariable<T>, callback: Callback<T, T>): Connection
			table.insert(callbacks, callback)
			return {Disconnect = function(): ()
				const index = table.find(callbacks, callback)
				if index then
					table.remove(callbacks, index)
				end
			end}
		end;

		Once = function(self: TrackedVariable<T>, callback: Callback<T, T>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function(): ()
				const index = table.find(waiting, callback)
				if index then
					table.remove(waiting, index)
				end
			end}
		end;

		Wait = function(self: TrackedVariable<T>, timeout: number?): (boolean, T, T)
			const co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					const index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			const returns = {coroutine.yield()}
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return (table.unpack :: any)(returns)
		end;

		WaitFor = function(self: TrackedVariable<T>, value: T, timeout: number?): (boolean, T?)
			if self:Get() == value then
				return true, nil
			end
			const co = coroutine.running()
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			local success: boolean, oldValue: T?, newValue: T?
			repeat
				success, oldValue, newValue = self:Wait()
			until not success or newValue == value
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return success, oldValue
		end;

		DisconnectAll = function(self: TrackedVariable<T>): ()
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" and coroutine.status(callback) == "suspended" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	return table.freeze(actions) :: TrackedVariable<T>
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return table.freeze(New)
