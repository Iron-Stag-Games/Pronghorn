--!strict
--!optimize 2
--!native
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
type Properties = {[string]: any, Children: {Instance}?, Attributes: {[string]: any}?, Tags: {string}?}
export type Callback<T...> = (T...) -> ()
export type Connection = {Disconnect: (self: Connection) -> ()}
export type Event<T...> = {
	Fire: (self: Event<T...>, T...) -> ();
	Connect: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Once: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Wait: (self: Event<T...>, timeout: number?) -> (T...); -- Note: variadics can't be made nullable yet
	DisconnectAll: (self: Event<T...>) -> ();
}
export type TrackedVariable<T> = {
	Get: (self: TrackedVariable<T>) -> (T);
	Set: (self: TrackedVariable<T>, value: T) -> ();
	Connect: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Once: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Wait: (self: TrackedVariable<T>) -> (T, T) & (self: TrackedVariable<T>, timeout: number) -> (T?, T?);
	DisconnectAll: (self: TrackedVariable<T>) -> ();
}

-- Constants
local QUEUED_EVENT_QUEUE_SIZE = 256

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Applies properties, attributes, tags, callbacks, and children to an Instance.
--- @param instance -- The Instance to apply to.
--- @param properties -- A table of properties to apply to the Instance.
function New.Properties<T>(instance: T, properties: Properties): ()
	assert(typeof(instance) == "Instance", "Attempt to apply properties to a non-Instance")

	for key, value in properties do
		if key == "Children" then
			for _, child in value do
				child.Parent = instance
			end
		elseif key == "Attributes" then
			for attributeName, attribute in value do
				instance:SetAttribute(attributeName, attribute)
			end
		elseif key == "Tags" then
			for _, tag in value do
				instance:AddTag(tag)
			end
		elseif typeof((instance :: any)[key]) == "RBXScriptSignal" then
			(instance :: any)[key]:Connect(value)
		else
			(instance :: any)[key] = value
		end
	end
end

--- Creates and returns a new Instance.
--- @param className -- The ClassName for the Instance being created.
--- @param parent? -- The Parent for the Instance after creation.
--- @param name? -- The Name for the Instance.
--- @param properties? -- A table of properties to apply to the Instance.
--- @return Instance -- The new Instance.
--- @error Parent parameter used more than once -- Incorrect usage.
--- @error Name parameter used more than once -- Incorrect usage.
--- @error Properties parameter used more than once -- Incorrect usage.
function New.Instance(className: string, ...: (Instance | string | Properties)?): any
	local parent: Instance?, name: string?, properties: Properties?;
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
		New.Properties(newInstance, properties)
	end
	if parent then
		newInstance.Parent = parent
	end

	return newInstance
end

--- Clones and returns an Instance.
--- @param instance -- The Instance to clone from.
--- @param parent? -- The Parent for the cloned Instance after creation.
--- @param name? -- The Name for the cloned Instance.
--- @param properties? -- A table of properties to apply to the cloned Instance.
--- @return Instance -- The cloned Instance.
--- @error Attempt to clone non-Instance -- Incorrect usage.
--- @error Parent parameter used more than once -- Incorrect usage.
--- @error Name parameter used more than once -- Incorrect usage.
--- @error Properties parameter used more than once -- Incorrect usage.
function New.Clone<T>(instance: T, ...: (Instance | string | Properties)?): T
	assert(typeof(instance) == "Instance", "Attempt to clone non-Instance")

	local parent: Instance?, name: string?, properties: Properties?;
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
		New.Properties(newInstance, properties)
	end
	if parent then
		newInstance.Parent = parent
	end

	return newInstance
end

--- Creates and returns an Event.
--- @return Event -- The new Event.
function New.Event(): Event<...any>
	local callbacks: {Callback<...any>} = {}
	local waiting: {Callback<...any> | thread} = {}

	local actions: Event<...any> = {
		Fire = function(_, ...: any)
			local currentlyWaiting = table.clone(waiting)
			table.clear(waiting)
			for _, callback in callbacks do
				task.spawn(callback, ...)
			end
			for _, callback in currentlyWaiting do
				if typeof(callback) == "thread" and coroutine.status(callback) ~= "suspended" then continue end
				task.spawn(callback, ...)
			end
		end;

		Connect = function(_, callback: Callback<...any>)
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(_, callback: Callback<...any>)
			table.insert(waiting, callback)
			return {Disconnect = function()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(_, timeout: number?)
			local co = coroutine.running()
			table.insert(waiting, co)
			if timeout then
				task.delay(timeout, function()
					local index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co)
					end
				end)
			end
			return coroutine.yield()
		end;

		DisconnectAll = function(_)
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	table.freeze(actions)

	return actions
end

--- Creates and returns a QueuedEvent.
--- @param nameHint? -- The name of the QueuedEvent for debugging.
--- @return QueuedEvent -- The new QueuedEvent.
function New.QueuedEvent(nameHint: string?): Event<...any>
	local callbacks: {Callback<...any>} = {}
	local waiting: {Callback<...any> | thread} = {}
	local queueCount = 0
	local queuedEventCoroutines: {thread} = {}

	local function resumeQueuedEventCoroutines()
		for _, co in queuedEventCoroutines do
			task.spawn(co)
		end
		table.clear(queuedEventCoroutines)
		queueCount = 0
	end

	local actions: Event<...any> = {
		Fire = function(_, ...: any)
			if not next(callbacks) and not next(waiting) then
				if queueCount >= QUEUED_EVENT_QUEUE_SIZE then
					task.spawn(error, `QueuedEvent invocation queue exhausted{if nameHint then ` for '{nameHint}'` else ""}; did you forget to connect to it?`, 0)
				end
				queueCount += 1
				table.insert(queuedEventCoroutines, coroutine.running())
				coroutine.yield()
			end
			local currentlyWaiting = table.clone(waiting)
			table.clear(waiting)
			for _, callback in callbacks do
				task.spawn(callback, ...)
			end
			for _, callback in currentlyWaiting do
				if typeof(callback) == "thread" and coroutine.status(callback) ~= "suspended" then continue end
				task.spawn(callback, ...)
			end
		end;

		Connect = function(_, callback: Callback<...any>)
			resumeQueuedEventCoroutines()
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(_, callback: Callback<...any>)
			resumeQueuedEventCoroutines()
			table.insert(waiting, callback)
			return {Disconnect = function()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(_, timeout: number?)
			resumeQueuedEventCoroutines()
			local co = coroutine.running()
			table.insert(waiting, co)
			if timeout then
				task.delay(timeout, function()
					local index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co)
					end
				end)
			end
			return coroutine.yield()
		end;

		DisconnectAll = function(_)
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	table.freeze(actions)

	return actions
end

--- Creates and returns a TrackedVariable.
--- @param variable -- The initial value of the TrackedVariable.
--- @return TrackedVariable -- The new TrackedVariable.
function New.TrackedVariable(variable: any): TrackedVariable<any>
	local callbacks: {Callback<any, any>} = {}
	local waiting: {Callback<any, any> | thread} = {}

	local actions: TrackedVariable<any> = {
		Get = function(_): any
			return variable
		end;

		Set = function(_, newValue: any)
			if variable ~= newValue then
				local oldValue = variable
				variable = newValue
				local currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in callbacks do
					task.spawn(callback, oldValue, newValue)
				end
				for _, callback in currentlyWaiting do
					if typeof(callback) == "thread" and coroutine.status(callback) ~= "suspended" then continue end
					task.spawn(callback, oldValue, newValue)
				end
			end
		end;

		Connect = function(_, callback: Callback<any, any>)
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(_, callback: Callback<any, any>)
			table.insert(waiting, callback)
			return {Disconnect = function()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(_, timeout: number?)
			local co = coroutine.running()
			table.insert(waiting, co)
			if timeout then
				task.delay(timeout, function()
					local index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co)
					end
				end)
			end
			return coroutine.yield()
		end;

		DisconnectAll = function(_)
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	table.freeze(actions)

	return actions
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return New
