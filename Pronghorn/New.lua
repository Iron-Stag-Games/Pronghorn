--!strict
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local New = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Types
type Callback = (...any) -> ()
type Connection = {Disconnect: () -> ()}
export type Event = {
	Fire: (self: Event, ...any) -> ();
	Connect: (self: Event, callback: Callback) -> (Connection);
	Once: (self: Event, callback: Callback) -> (Connection);
	Wait: (self: Event) -> (any);
}
export type TrackedVariable = {
	Get: (self: TrackedVariable) -> (any);
	Set: (self: TrackedVariable, value: any) -> ();
	Connect: (self: TrackedVariable, callback: Callback) -> (Connection);
	Once: (self: TrackedVariable, callback: Callback) -> (Connection);
	Wait: (self: TrackedVariable) -> (any);
}

-- Constants
local QUEUED_EVENT_QUEUE_SIZE = 256

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates and returns a new Instance.
--- @param className -- The ClassName for the Instance being created.
--- @param parent? -- The Parent for the Instance after creation.
--- @param name? -- The Name for the Instance.
--- @param properties? -- A table of properties to apply to the Instance.
--- @return Instance -- The new Instance.
function New.Instance(className: string, ...: any?): any
	local parent: Instance?, name: string?, properties: {[string]: any, Children: {Instance}?}?
	for _, parameter in {...} do
		if typeof(parameter) == "Instance" then
			if parent then error("Parent parameter used more than once") end
			parent = parameter
		elseif type(parameter) == "string" or type(parameter) == "number" then
			if name then error("Name parameter used more than once") end
			name = tostring(parameter)
		elseif type(parameter) == "table" then
			if properties then error("Properties parameter used more than once") end
			properties = parameter
		end
	end

	local newInstance = Instance.new(className)

	if name then
		newInstance.Name = name
	end
	if properties then
		for key, value in properties do
			if key == "Children" then
				for _, child in value do
					child.Parent = newInstance
				end
			elseif typeof((newInstance :: any)[key]) == "RBXScriptSignal" then
				(newInstance :: any)[key]:Connect(value)
			else
				(newInstance :: any)[key] = value
			end
		end
	end
	if parent then
		newInstance.Parent = parent
	end

	return newInstance
end

--- Clones and returns and Instance.
--- @param instance -- The Instance to clone from.
--- @param parent? -- The Parent for the cloned Instance after creation.
--- @param name? -- The Name for the cloned Instance.
--- @param properties? -- A table of properties to apply to the cloned Instance.
--- @return Instance -- The cloned Instance.
function New.Clone<T>(instance: T, ...: any?): T
	assert(typeof(instance) == "Instance", "Attempt to clone non-Instance")

	local parent: Instance?, name: string?, properties: {[string]: any, Children: {Instance}?}?
	for _, parameter in {...} do
		if typeof(parameter) == "Instance" then
			if parent then error("Parent parameter used more than once") end
			parent = parameter
		elseif type(parameter) == "string" or type(parameter) == "number" then
			if name then error("Name parameter used more than once") end
			name = tostring(parameter)
		elseif type(parameter) == "table" then
			if properties then error("Properties parameter used more than once") end
			properties = parameter
		end
	end

	local newInstance = instance:Clone()

	if name then
		newInstance.Name = name
	end
	if properties then
		for key, value in properties do
			if key == "Children" then
				for _, child in value do
					child.Parent = newInstance
				end
			elseif typeof((newInstance :: any)[key]) == "RBXScriptSignal" then
				(newInstance :: any)[key]:Connect(value)
			else
				(newInstance :: any)[key] = value
			end
		end
	end
	if parent then
		newInstance.Parent = parent
	end

	return newInstance
end

--- Creates and returns an Event.
--- @return Event -- The new Event.
function New.Event(): Event
	local callbacks: {Callback} = {}

	local actions: Event = {
		Fire = function(_, ...: any?)
			for _, callback in callbacks do
				callback(...)
			end
		end;

		Connect = function(_, callback: Callback)
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(_, callback: Callback)
			local wrappedCallback: Callback; wrappedCallback = function(...: any?)
				callback(...)
				table.remove(callbacks, table.find(callbacks, wrappedCallback))
			end
			table.insert(callbacks, wrappedCallback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, wrappedCallback))
			end}
		end;

		Wait = function(_)
			local co = coroutine.running()
			local callback; callback = function(...: any?)
				task.spawn(co, ...)
				table.remove(callbacks, table.find(callbacks, callback))
			end
			table.insert(callbacks, callback)
			return coroutine.yield()
		end;
	}

	table.freeze(actions)

	return actions
end

--- Creates and returns a QueuedEvent.
--- @param nameHint? -- The name of the QueuedEvent for debugging.
--- @return QueuedEvent -- The new QueuedEvent.
function New.QueuedEvent(nameHint: string?): Event
	local callbacks: {Callback} = {}
	local queueCount = 0
	local queuedEventCoroutines: {thread} = {}

	local function resumeQueuedEventCoroutines()
		for _, co in queuedEventCoroutines do
			task.spawn(co)
		end
		table.clear(queuedEventCoroutines)
		queueCount = 0
	end

	local actions: Event = {
		Fire = function(_, ...: any?)
			if not next(callbacks) then
				if queueCount >= QUEUED_EVENT_QUEUE_SIZE then
					task.spawn(error, `QueuedEvent invocation queue exhausted{if nameHint then ` for '{nameHint}'` else ""}; did you forget to connect to it?`, 0)
				end
				queueCount += 1
				table.insert(queuedEventCoroutines, coroutine.running())
				coroutine.yield()
			end
			for _, callback in callbacks do
				callback(...)
			end
		end;

		Connect = function(_, callback: Callback)
			resumeQueuedEventCoroutines()
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(_, callback: Callback)
			resumeQueuedEventCoroutines()
			local wrappedCallback: Callback; wrappedCallback = function(...: any?)
				callback(...)
				table.remove(callbacks, table.find(callbacks, wrappedCallback))
			end
			table.insert(callbacks, wrappedCallback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, wrappedCallback))
			end}
		end;

		Wait = function(_)
			resumeQueuedEventCoroutines()
			local co = coroutine.running()
			local callback; callback = function(...: any?)
				task.spawn(co, ...)
				table.remove(callbacks, table.find(callbacks, callback))
			end
			table.insert(callbacks, callback)
			return coroutine.yield()
		end;
	}

	table.freeze(actions)

	return actions
end

--- Creates and returns a TrackedVariable.
--- @param variable -- The initial value of the TrackedVariable.
--- @return QueuedEvent -- The new TrackedVariable.
function New.TrackedVariable(variable: any): TrackedVariable
	local callbacks: {Callback} = {}

	local actions: TrackedVariable = {
		Get = function(_): any
			return variable
		end;

		Set = function(_, value: any)
			variable = value
			for _, callback in callbacks do
				callback(value)
			end
		end;

		Connect = function(_, callback: Callback)
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(_, callback: Callback)
			local wrappedCallback: Callback; wrappedCallback = function(value: any)
				callback(value)
				table.remove(callbacks, table.find(callbacks, wrappedCallback))
			end
			table.insert(callbacks, wrappedCallback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, wrappedCallback))
			end}
		end;

		Wait = function(_)
			local co = coroutine.running()
			local callback; callback = function(value: any)
				task.spawn(co, value)
				table.remove(callbacks, table.find(callbacks, callback))
			end
			table.insert(callbacks, callback)
			return coroutine.yield()
		end;
	}

	table.freeze(actions)

	return actions
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return New
