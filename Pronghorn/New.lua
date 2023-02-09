--!strict
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local New = shared.New

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

type Callback = (any) -> ()
type Connection = {Disconnect: () -> ()}
type Event = {
	Fire: (self: any, value: any) -> ();
	Connect: (self: any, callback: Callback) -> (Connection);
	Once: (self: any, callback: Callback) -> (Connection);
	Wait: (self: any) -> (any);
}
type TrackedVariable = {
	Get: (self: any) -> (any);
	Set: (self: any, value: any) -> ();
	Connect: (self: any, callback: Callback) -> (Connection);
	Once: (self: any, callback: Callback) -> (Connection);
	Wait: (self: any) -> (any);
}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function New.Instance(className: string, ...): Instance
	local parent: Instance?, name: string?, properties: {[string]: any}?
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
			newInstance[key] = value
		end
	end
	if parent then
		newInstance.Parent = parent
	end

	return newInstance
end

function New.Event(): Event
	local callbacks: {Callback} = {}
	local actions: Event = {
		Fire = function(_, value: any)
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
			local Coroutine = coroutine.running()
			local callback; callback = function(value: any)
				coroutine.resume(Coroutine, value)
				table.remove(callbacks, table.find(callbacks, callback))
			end
			table.insert(callbacks, callback)
			return coroutine.yield()
		end;
	}

	table.freeze(actions)

	return actions
end

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
				coroutine.resume(co, value)
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
