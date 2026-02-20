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
local Warn = require(script.Parent.Debug).Warn

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Types
export type Callback<T...> = (T...) -> ()
export type Connection = {Disconnect: (self: Connection) -> ()}
export type Event<T...> = {
	Fire: (self: Event<T...>, T...) -> ();
	Connect: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Once: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Wait: (self: Event<T...>, timeout: number?) -> (boolean, T...);
	DisconnectAll: (self: Event<T...>) -> ();
}
export type TrackedVariable<T> = {
	Get: (self: TrackedVariable<T>) -> (T);
	Set: (self: TrackedVariable<T>, value: T) -> ();
	Connect: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Once: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Wait: (self: TrackedVariable<T>, timeout: number?) -> (boolean, T, T);
	WaitFor: (self: TrackedVariable<T>, value: T, timeout: number?) -> (boolean, T, T);
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
local localPlayer = Players.LocalPlayer :: Player

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Parents all children to an instance.
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
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function(): ()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): (boolean, ...any)
			local co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					local index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			local returns = {coroutine.yield()}
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

	table.freeze(actions)

	return actions
end

--- Creates and returns a `QueuedEvent`.
--- @param nameHint? -- The name of the `QueuedEvent` for debugging.
--- @param queueSize? -- The queue size of the `QueuedEvent`.
--- @return Event<...any> -- The new `QueuedEvent`.
function New.QueuedEvent(nameHint: string?, queueSize: number?): Event<...any>
	queueSize = queueSize or QUEUED_EVENT_QUEUE_SIZE

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
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			resumeQueuedEventInvocations(self)
			return {Disconnect = function(): ()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): (boolean, ...any)
			local queuedInvocation = resumeQueuedEventInvocations(self)
			if queuedInvocation then
				return true, table.unpack(queuedInvocation)
			end
			local co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					local index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			local returns = {coroutine.yield()}
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
					if typeof(callback) == "thread" then
						if coroutine.status(callback) ~= "suspended" then continue end
						task.spawn(callback, true, oldValue, newValue)
					else
						task.spawn(callback, oldValue, newValue)
					end
				end
			end
		end;

		Connect = function(self: TrackedVariable<any>, callback: Callback<any, any>): Connection
			table.insert(callbacks, callback)
			return {Disconnect = function(): ()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(self: TrackedVariable<any>, callback: Callback<any, any>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function(): ()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(self: TrackedVariable<any>, timeout: number?): (boolean, any?, any?)
			local co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					local index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			local returns = {coroutine.yield()}
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return table.unpack(returns)
		end;

		WaitFor = function(self: TrackedVariable<any>, value: any, timeout: number?): (boolean, any?, any?)
			error("Unimplemented")
		end;

		DisconnectAll = function(self: TrackedVariable<any>): ()
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" and coroutine.status(callback) == "suspended" then
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

		local container = Instance.new("ScreenGui")
		container.Name = `__instanceStream_{uid}`
		container.Enabled = false
		container.ResetOnSpawn = false

		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.OnServerEvent:Connect(function(): ()
			if not exclusive then
				container:Destroy()
				for _, connection in ancestryListeners do
					connection:Disconnect()
				end
			end
		end)
		remoteEvent.Parent = container

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
			local objectValue = Instance.new("ObjectValue")
			objectValue.Name = tostring(index)
			objectValue.Value = instance
			objectValue:SetAttribute("FullName", instance:GetFullName())
			New.Children(objectValue, if exclusive then {instance} else nil)
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
--- @return Event<...Instance?> -- The `Event` that fires when the `ClientInstanceStream` has received all `Instances`.
--- @return Event<Instance?> -- The `Event` that fires when an `Instance` is received.
--- @return Instance -- The container for the `ServerInstanceStream`.
--- @error ClientInstanceStream cannot be created on the server -- Incorrect usage.
function New.ClientInstanceStream(uid: string): (Event<...Instance?>, Event<Instance?>, Instance)
	if IS_SERVER then error("ClientInstanceStream cannot be created on the server", 0) end

	local container = assert(localPlayer.PlayerGui:WaitForChild("__instanceStream_" .. uid, 30), `Cannot find InstanceStream with UID "{uid}"`) :: ScreenGui
	local remoteEvent = assert(container:WaitForChild("RemoteEvent", 30), `InstanceStream with UID "{uid}" missing RemoteEvent`) :: RemoteEvent
	local numInstances = assert(tonumber(uid:split("_")[2]))
	local instances: {Instance} = {}
	local failedInstances: {true} = {}
	local finished = false
	local finishedEvent = New.QueuedEvent("InstanceStream Finished Event") :: Event<...Instance?>
	local streamEvent = New.QueuedEvent("InstanceStream Stream Event", math.huge) :: Event<Instance?>

	local function checkFinished(): boolean
		if finished then return true end
		for index = 1, numInstances do
			if not instances[index] and not failedInstances[index] then
				return false
			end
		end
		finished = true
		finishedEvent:Fire(table.unpack(instances))
		finishedEvent:DisconnectAll()
		streamEvent:DisconnectAll()
		remoteEvent:FireServer()
		Print(`InstanceStream "{uid}" finished`)
		return true
	end

	container.Destroying:Once(function(): ()
		for _, child in container:GetChildren() do
			if child:IsA("ObjectValue") and not child.Value and not child:GetAttribute("Canceled") then
				child:SetAttribute("Canceled", true)
			end
		end
		finishedEvent:DisconnectAll()
		streamEvent:DisconnectAll()
	end)

	container.Parent = localPlayer

	Print(`InstanceStream "{uid}" starting`)

	for _, child in container:GetChildren() do
		if not child:IsA("ObjectValue") then continue end
		if child:GetAttribute("Canceled") then
			Warn(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
			failedInstances[tonumber(child.Name) :: number] = true
			streamEvent:Fire(nil)
			checkFinished()
		elseif child.Value then
			Print(`InstanceStream "{uid}" received "{child.Name}": {child.Value:GetFullName()}`)
			instances[tonumber(child.Name) :: number] = child.Value
			streamEvent:Fire(child.Value)
		else
			child:GetAttributeChangedSignal("Canceled"):Once(function(): ()
				Warn(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
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
			if not child:IsA("ObjectValue") then return end
			child:GetAttributeChangedSignal("Canceled"):Once(function(): ()
				Warn(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
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
