--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local New = {} local Global, Modules, Remotes, Print, Warn, Trace -- Core Module boilerplate only. Do not use!

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function New.Instance(ClassName: string, ...): Instance
	local Parent: Instance?, Name: string?, Properties: {[string]: any}?
	for _, Parameter in {...} do
		if typeof(Parameter) == "Instance" then
			if Parent then error("Parent parameter used more than once") end
			Parent = Parameter
		elseif type(Parameter) == "string" then
			if Name then error("Name parameter used more than once") end
			Name = Parameter
		elseif type(Parameter) == "table" then
			if Properties then error("Properties parameter used more than once") end
			Properties = Parameter
		end
	end

	local NewInstance = Instance.new(ClassName)

	if Name then
		NewInstance.Name = Name
	end
	if Properties then
		for Key, Value in Properties do
			NewInstance[Key] = Value
		end
	end
	if Parent then
		NewInstance.Parent = Parent
	end

	return NewInstance
end

function New.Event(): {
	Fire: (any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	ConnectOnce: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}

	local Callbacks: any = {}
	local Actions: any = {}

	function Actions:Fire(Value: any)
		for _, Callback in Callbacks do
			Callback(Value)
		end
	end

	function Actions:Connect(Function: (any) -> ())
		table.insert(Callbacks, Function)
		return {Disconnect = function()
			table.remove(Callbacks, table.find(Callbacks, Function))
		end}
	end

	function Actions:ConnectOnce(Function: (any) -> ())
		local Callback; Callback = function(Value: any)
			Function(Value)
			table.remove(Callbacks, table.find(Callbacks, Callback))
		end
		table.insert(Callbacks, Callback)
		return {Disconnect = function()
			table.remove(Callbacks, table.find(Callbacks, Callback))
		end}
	end

	function Actions:Wait()
		local Coroutine = coroutine.running()
		local Callback; Callback = function(Value: any)
			coroutine.resume(Coroutine, Value)
			table.remove(Callbacks, table.find(Callbacks, Callback))
		end
		table.insert(Callbacks, Callback)
		return coroutine.yield()
	end

	table.freeze(Actions)

	return Actions
end

function New.TrackedVariable(Variable: any): {
	Get: () -> (any);
	Set: (Value: any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	ConnectOnce: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}

	local Callbacks: any = {}
	local Actions: any = {}

	function Actions:Get(): any
		return Variable
	end

	function Actions:Set(Value: any)
		Variable = Value
		for _, Callback in Callbacks do
			Callback(Value)
		end
	end

	function Actions:Connect(Function: (any) -> ())
		table.insert(Callbacks, Function)
		return {Disconnect = function()
			table.remove(Callbacks, table.find(Callbacks, Function))
		end}
	end

	function Actions:ConnectOnce(Function: (any) -> ())
		local Callback; Callback = function(Value: any)
			Function(Value)
			table.remove(Callbacks, table.find(Callbacks, Callback))
		end
		table.insert(Callbacks, Callback)
		return {Disconnect = function()
			table.remove(Callbacks, table.find(Callbacks, Callback))
		end}
	end

	function Actions:Wait()
		local Coroutine = coroutine.running()
		local Callback; Callback = function(Value: any)
			coroutine.resume(Coroutine, Value)
			table.remove(Callbacks, table.find(Callbacks, Callback))
		end
		table.insert(Callbacks, Callback)
		return coroutine.yield()
	end

	table.freeze(Actions)

	return Actions
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return function(A, B, C, D, E, F, _) Global, Modules, Remotes, Print, Warn, Trace = A, B, C, D, E, F return New end -- Core Module boilerplate only. Do not use!
