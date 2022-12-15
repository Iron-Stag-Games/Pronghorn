--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local New = shared.New

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

function New.Event(): {
	Fire: (any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Once: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}

	local callbacks: any = {}
	local actions: any = {}

	function actions:Fire(value: any)
		for _, callback in callbacks do
			callback(value)
		end
	end

	function actions:Connect(callbackFunction: (any) -> ())
		table.insert(callbacks, callbackFunction)
		return {Disconnect = function()
			table.remove(callbacks, table.find(callbacks, callbackFunction))
		end}
	end

	function actions:Once(callbackFunction: (any) -> ())
		local callback; callback = function(value: any)
			callbackFunction(value)
			table.remove(callbacks, table.find(callbacks, callback))
		end
		table.insert(callbacks, callback)
		return {Disconnect = function()
			table.remove(callbacks, table.find(callbacks, callback))
		end}
	end

	function actions:Wait()
		local Coroutine = coroutine.running()
		local callback; callback = function(value: any)
			coroutine.resume(Coroutine, value)
			table.remove(callbacks, table.find(callbacks, callback))
		end
		table.insert(callbacks, callback)
		return coroutine.yield()
	end

	table.freeze(actions)

	return actions
end

function New.TrackedVariable(variable: any): {
	Get: () -> (any);
	Set: (value: any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Once: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}

	local callbacks: any = {}
	local actions: any = {}

	function actions:Get(): any
		return variable
	end

	function actions:Set(value: any)
		variable = value
		for _, callback in callbacks do
			callback(value)
		end
	end

	function actions:Connect(callbackFunction: (any) -> ())
		table.insert(callbacks, callbackFunction)
		return {Disconnect = function()
			table.remove(callbacks, table.find(callbacks, callbackFunction))
		end}
	end

	function actions:Once(callbackFunction: (any) -> ())
		local callback; callback = function(value: any)
			callbackFunction(value)
			table.remove(callbacks, table.find(callbacks, callback))
		end
		table.insert(callbacks, callback)
		return {Disconnect = function()
			table.remove(callbacks, table.find(callbacks, callback))
		end}
	end

	function actions:Wait()
		local co = coroutine.running()
		local callback; callback = function(value: any)
			coroutine.resume(co, value)
			table.remove(callbacks, table.find(callbacks, callback))
		end
		table.insert(callbacks, callback)
		return coroutine.yield()
	end

	table.freeze(actions)

	return actions
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return New
