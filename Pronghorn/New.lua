--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local New: any, Global: any, Modules: any, Remotes: any = {}, nil, nil, nil

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function New.Instance(ClassName: string, Parent: Instance, Name: string?, Properties: {[string]: any}): Instance
	local NewInstance = Instance.new(ClassName)

	if Name then
		NewInstance.Name = Name
	end
	if Properties then
		for Key, Value in Properties do
			NewInstance[Key] = Value
		end
	end
	NewInstance.Parent = Parent

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

return function(GlobalEnv, ModulesEnv, RemotesEnv) Global, Modules, Remotes = GlobalEnv, ModulesEnv, RemotesEnv return New end
