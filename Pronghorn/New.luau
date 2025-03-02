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
-- Dependencies
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Core
local Print = require(script.Parent.Debug).Print

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
	WaitFor: (self: Event<T...>, timeout: number?) -> (T...); -- Note: variadics can't be made nullable yet
	DisconnectAll: (self: Event<T...>) -> ();
}
export type TrackedVariable<T> = {
	Get: (self: TrackedVariable<T>) -> (T);
	Set: (self: TrackedVariable<T>, value: T) -> ();
	Connect: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Once: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Wait: (self: TrackedVariable<T>) -> (T, T) & (self: TrackedVariable<T>, timeout: number) -> (T?, T?);
	WaitFor: (self: TrackedVariable<T>) -> (T, T) & (self: TrackedVariable<T>, timeout: number) -> (T?, T?);
	DisconnectAll: (self: TrackedVariable<T>) -> ();
}
export type InstanceStream<T...> = {
	Instances: {Instance};
	Start: (self: InstanceStream<T...>, players: Player | {Player}, instances: {Instance}) -> (string);
	Listen: (self: InstanceStream<T...>, uid: string) -> (Event<T...>, Event<Instance>);
}

-- Constants
local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()
local QUEUED_EVENT_QUEUE_SIZE = 256

-- Objects
local localPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Applies properties, attributes, tags, callbacks, and children to an `Instance`.
--- @param instance -- The `Instance` to apply to.
--- @param properties -- A table of properties to apply to the `Instance`.
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
--- @param className -- The `ClassName` for the `Instance` being created.
--- @param parent? -- The `Parent` for the `Instance` after creation.
--- @param name? -- The `Name` for the `Instance`.
--- @param properties? -- A table of properties to apply to the `Instance`.
--- @return any -- The new `Instance`.
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

--- Clones and returns an `Instance`.
--- @param instance -- The `Instance` to clone from.
--- @param parent? -- The `Parent` for the cloned `Instance` after creation.
--- @param name? -- The `Name` for the cloned `Instance`.
--- @param properties? -- A table of properties to apply to the cloned `Instance`.
--- @return T -- The cloned `Instance`.
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

--- Creates and returns an `Event`.
--- @return Event<...any> -- The new `Event`.
function New.Event(): Event<...any>
	local callbacks: {Callback<...any>} = {}
	local waiting: {Callback<...any> | thread} = {}

	local actions: Event<...any> = {
		Fire = function(self: Event<...any>, ...: any): ()
			local currentlyWaiting = table.clone(waiting)
			table.clear(waiting)
			for _, callback in table.clone(callbacks) do
				task.spawn(callback, ...)
			end
			for _, callback in currentlyWaiting do
				if typeof(callback) == "thread" and coroutine.status(callback) ~= "suspended" then continue end
				task.spawn(callback, ...)
			end
		end;

		Connect = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): ...any
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

		WaitFor = function(self: Event<any>, timeout: number?): ()
			error("Unimplemented")
		end;

		DisconnectAll = function(self: Event<...any>): ()
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

--- Creates and returns a `QueuedEvent`.
--- @param nameHint? -- The name of the `QueuedEvent` for debugging.
--- @param queueSize? -- The queue size of the `QueuedEvent`.
--- @return Event<...any> -- The new `QueuedEvent`.
function New.QueuedEvent(nameHint: string?, queueSize: number?): Event<...any>
	queueSize = queueSize or QUEUED_EVENT_QUEUE_SIZE
	assert(queueSize)

	local callbacks: {Callback<...any>} = {}
	local waiting: {Callback<...any> | thread} = {}
	local queueCount = 0
	local queuedEventInvocations: {{any}} = {}

	local function resumeQueuedEventInvocations(self: Event<...any>): {any}?
		local _, firstInvocation = next(queuedEventInvocations)

		if next(callbacks) or next(waiting) then
			for _, invocation in queuedEventInvocations do
				self:Fire(table.unpack(invocation))
			end
		end

		table.clear(queuedEventInvocations)
		queueCount = 0

		return firstInvocation
	end

	local actions: Event<...any> = {
		Fire = function(self: Event<...any>, ...: any): ()
			if not next(callbacks) and not next(waiting) then
				if queueCount >= queueSize then
					task.spawn(error, `QueuedEvent invocation queue exhausted{if nameHint then ` for "{nameHint}"` else ""}; did you forget to connect to it?`, 0)
				end
				queueCount += 1
				table.insert(queuedEventInvocations, {...})
			else
				local currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in table.clone(callbacks) do
					task.spawn(callback, ...)
				end
				for _, callback in currentlyWaiting do
					if typeof(callback) == "thread" and coroutine.status(callback) ~= "suspended" then continue end
					task.spawn(callback, ...)
				end
			end
		end;

		Connect = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(callbacks, callback)
			resumeQueuedEventInvocations(self)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			resumeQueuedEventInvocations(self)
			return {Disconnect = function()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): ...any
			local queuedInvocation = resumeQueuedEventInvocations(self)
			if queuedInvocation then
				return table.unpack(queuedInvocation)
			end
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

		WaitFor = function(self: Event<any>, timeout: number?): ()
			error("Unimplemented")
		end;

		DisconnectAll = function(self: Event<...any>): ()
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

--- Creates and returns a `TrackedVariable`.
--- @param variable -- The initial value of the `TrackedVariable`.
--- @return TrackedVariable<any> -- The new `TrackedVariable`.
function New.TrackedVariable(variable: any): TrackedVariable<any>
	local callbacks: {Callback<any, any>} = {}
	local waiting: {Callback<any, any> | thread} = {}

	local actions: TrackedVariable<any> = {
		Get = function(self: TrackedVariable<any>): any
			return variable
		end;

		Set = function(self: TrackedVariable<any>, newValue: any): ()
			if variable ~= newValue then
				local oldValue = variable
				variable = newValue
				local currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in table.clone(callbacks) do
					task.spawn(callback, oldValue, newValue)
				end
				for _, callback in currentlyWaiting do
					if typeof(callback) == "thread" and coroutine.status(callback) ~= "suspended" then continue end
					task.spawn(callback, oldValue, newValue)
				end
			end
		end;

		Connect = function(self: TrackedVariable<any>, callback: Callback<any, any>): Connection
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(self: TrackedVariable<any>, callback: Callback<any, any>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(self: TrackedVariable<any>, timeout: number?): ()
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

		WaitFor = function(self: TrackedVariable<any>, timeout: number?): ()
			error("Unimplemented")
		end;

		DisconnectAll = function(self: TrackedVariable<any>): ()
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

--- Starts a `ServerInstanceStream` and returns its UID and any newly created `Instances`.
--- @param players -- The list of `Players` to stream `Instances` to.
--- @param instances -- The list of `Instances` to stream.
--- @param exclusive? -- Whether or not to exclusively replicate the list of `Instances` by moving them into `PlayerGui`. If the first argument is an array of `Players`, the `Instances` are cloned.
--- @return string -- The UID of the `ServerInstanceStream`.
--- @return {[Player]: Instance}? -- The containers which were created as a result of `exclusive?` = `true`.
--- @return {[Player]: {any}}? -- The `Instances` which were cloned as a result of `players` = `{Player}` and `exclusive?` = `true`.
--- @error ServerInstanceStream cannot be created on the client -- Incorrect usage.
function New.ServerInstanceStream(players: Player | {Player}, instances: {Instance}, exclusive: boolean?): (string, {[Player]: Instance}?, {[Player]: {any}}?)
	if IS_CLIENT then error("ServerInstanceStream cannot be created on the client", 0) end

	local uid = `{HttpService:GenerateGUID(false)}_{#instances}`
	local containers: {[Player]: Instance}? = if exclusive then {} else nil
	local clonedInstances: {[Player]: {any}}? = if exclusive and type(players) == "table" then {} else nil
	local ancestryListeners: {RBXScriptConnection} = {}

	for _, player in (if type(players) == "table" then players else {players}) :: {Player} do
		if not player.Parent then continue end

		local container: RemoteEvent; container = New.Instance("RemoteEvent", `__instanceStream_{uid}`, {
			OnServerEvent = function(): ()
				if not exclusive then
					container:Destroy()
					for _, connection in ancestryListeners do
						connection:Disconnect()
					end
				end
			end;
		})

		if containers then
			containers[player] = container
		end

		if clonedInstances then
			clonedInstances[player] = {}
		end

		for index, instance in instances do
			if clonedInstances then
				instance = instance:Clone()
				clonedInstances[player][index] = instance
			end
			local objectValue: ObjectValue = New.Instance("ObjectValue", tostring(index), {
				Value = instance;
				Children = if exclusive then {instance} else nil;
			})
			objectValue:SetAttribute("FullName", instance:GetFullName())
			objectValue.Parent = container

			table.insert(ancestryListeners, instance.AncestryChanged:Connect(function(): ()
				if not instance.Parent then
					objectValue:SetAttribute("Canceled", true)
				end
			end))
		end

		container.Parent = player.PlayerGui

		if not exclusive then
			task.delay(30, container.Destroy, container)
		end
	end

	return uid, containers, clonedInstances
end

--- Listens to a `ServerInstanceStream` and returns activity `Events`.
--- @param uid -- The UID of the `ServerInstanceStream`.
--- @return Event<...any?> -- The `Event` that fires when the `ClientInstanceStream` has received all `Instances`.
--- @return Event<any?> -- The `Event` that fires when an `Instance` is received.
--- @return Instance -- The container for the `ServerInstanceStream`.
--- @error ClientInstanceStream cannot be created on the server -- Incorrect usage.
function New.ClientInstanceStream(uid: string): (Event<...any?>, Event<any?>, Instance)
	if IS_SERVER then error("ClientInstanceStream cannot be created on the server", 0) end

	local container = assert(localPlayer.PlayerGui:FindFirstChild("__instanceStream_" .. uid), `Cannot find InstanceStream with UID "{uid}"`) :: RemoteEvent
	local numInstances = assert(tonumber(uid:split("_")[2]))
	local instances: {Instance} = {}
	local failedInstances: {true} = {}
	local finishedEvent: Event<...Instance?> = New.QueuedEvent("InstanceStream Finished Event")
	local streamEvent: Event<Instance?> = New.QueuedEvent("InstanceStream Stream Event", math.huge)

	local function checkFinished(): boolean
		for index = 1, numInstances do
			if not instances[index] and not failedInstances[index] then
				return false
			end
		end
		finishedEvent:Fire(table.unpack(instances))
		finishedEvent:DisconnectAll()
		streamEvent:DisconnectAll()
		container:FireServer()
		Print(`InstanceStream "{uid}" finished`)
		return true
	end

	container.Destroying:Once(function(): ()
		finishedEvent:DisconnectAll()
		streamEvent:DisconnectAll()
	end)

	container.Parent = localPlayer

	Print(`InstanceStream "{uid}" starting`)

	for _, child in container:GetChildren() do
		assert(child:IsA("ObjectValue"))
		if child.Value then
			Print(`InstanceStream "{uid}" received "{child.Name}": {child.Value:GetFullName()}`)
			instances[tonumber(child.Name) :: number] = child.Value
			streamEvent:Fire(child.Value)
		else
			child:GetAttributeChangedSignal("Canceled"):Once(function(): ()
				Print(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
				failedInstances[tonumber(child.Name) :: number] = true
				streamEvent:Fire(nil)
				checkFinished()
			end)
			child.Changed:Once(function(): ()
				assert(child.Value)
				Print(`InstanceStream "{uid}" received "{child.Name}": {child.Value:GetFullName()}`)
				instances[tonumber(child.Name) :: number] = child.Value
				streamEvent:Fire(child.Value)
				checkFinished()
			end)
		end
	end

	if not checkFinished() then
		container.ChildAdded:Connect(function(child: Instance): ()
			assert(child:IsA("ObjectValue"))
			child:GetAttributeChangedSignal("Canceled"):Once(function(): ()
				Print(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
				failedInstances[tonumber(child.Name) :: number] = true
				streamEvent:Fire(nil)
				checkFinished()
			end)
			child.Changed:Once(function(): ()
				assert(child.Value)
				Print(`InstanceStream "{uid}" received "{child.Name}": {child.Value:GetFullName()}`)
				instances[tonumber(child.Name) :: number] = child.Value
				streamEvent:Fire(child.Value)
				checkFinished()
			end)
		end)
	end

	return finishedEvent, streamEvent, container
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return New
