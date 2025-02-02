--!strict
--!optimize 2
--!native
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local a = if game:GetService("RunService"):IsServer() then "__s" else "__c"
if not script:GetAttribute(a) then script:SetAttribute(a, true) else error("Required Pronghorn/Remotes from more than one Script; please use included BindableFunctions", 0) end

local Remotes = {Server = {}, Client = {}}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Core
local Print = require(script.Parent.Debug).Print
local New = require(script.Parent.New)

-- Child Modules
local TypeChecker = require(script.TypeChecker)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Types
type ServerRemote = {
	Fire: (self: ServerRemote, players: Player | {Player}, ...any) -> (...any);
	FireAll: (self: ServerRemote, ...any) -> ();
	FireAllExcept: (self: ServerRemote, ignorePlayer: Player, ...any) -> ();
	SetListener: (self: ServerRemote, newFunction: (Player, ...any) -> (...any)) -> ();
	AddListener: (self: ServerRemote, newFunction: (Player, ...any) -> ()) -> RBXScriptConnection;
	Destroy: (self: ServerRemote) -> ();
}
type ClientRemote = typeof(setmetatable({} :: {
	Fire: (self: ClientRemote, ...any) -> (...any);
	Connect: (self: ClientRemote, func: (...any) -> ()) -> RBXScriptConnection;
	ConnectDeferred: (self: ClientRemote, func: (...any) -> ()) -> {Connected: boolean, Disconnect: (self: any) -> ()};
}, {} :: {
	__call: (self: ClientRemote, context: any, ...any) -> (...any)
}))

-- Constants
local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

-- Objects
local remotesFolder: Folder;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function getEnvironment(): string
	local info = debug.info(2, "s") or "ERR_DEBUG.INFO_RETURNED_NIL"
	local split = info:split(".")
	return "[" .. split[#split] .. "]"
end

local function connectEventClient(remote: RemoteFunction | UnreliableRemoteEvent | RemoteEvent): ()
	local moduleName: string = (remote :: any).Parent.Name
	local debugPrintText = `{moduleName}:{remote.Name}`
	local actions: any = {}
	local metaTable: any = {
		__call = function(_, context: any, ...: any): ...any
			if context ~= Remotes.Client[moduleName] then error(`Must call {moduleName}:{remote.Name}() with a colon`, 0) end
			return actions:Fire(...)
		end;
	}

	if not Remotes.Client[moduleName] then
		Remotes.Client[moduleName] = {}
	end
	Remotes.Client[moduleName][remote.Name] = setmetatable(actions, metaTable) :: ClientRemote

	if remote:IsA("RemoteFunction") then

		actions.Connect = function(_, func: (...any) -> (...any)): ()
			remote.OnClientInvoke = func
		end

		actions.ConnectDeferred = function(_, func: (...any) -> (...any)): ()
			task.defer(function()
				remote.OnClientInvoke = func
			end)
		end

		actions.Fire = function(_, ...: any): ...any
			Print(getEnvironment(), debugPrintText, {...})
			return remote:InvokeServer(...)
		end

	elseif remote:IsA("UnreliableRemoteEvent") or remote:IsA("RemoteEvent") then

		local lastServerTime: number;

		actions.Connect = function(_, func: (...any) -> ()): RBXScriptConnection
			return (remote :: RemoteEvent).OnClientEvent:Connect(func)
		end

		actions.ConnectDeferred = function(_, func: (...any) -> ()): {Connected: boolean, Disconnect: (self: any) -> ()}
			local connection: RBXScriptConnection?;
			local proxy; proxy = {
				Connected = false;
				Disconnect = function(self: any): ()
					assert(connection, "Disconnect was called before remote had connected"):Disconnect()
					proxy.Connected = false
				end
			}
			task.defer(function()
				connection = (remote :: RemoteEvent).OnClientEvent:Connect(func)
				proxy.Connected = true
			end)
			return proxy
		end

		actions.Fire = function(_, ...: any): ()
			if remote:IsA("UnreliableRemoteEvent") then
				local nextServerTime = script:GetAttribute("ServerTime") :: number
				if nextServerTime == lastServerTime then return end
				lastServerTime = nextServerTime
			end
			Print(getEnvironment(), debugPrintText, {...});
			(remote :: RemoteEvent):FireServer(...)
		end
	end
end

local function haveClientEventsLoaded(): boolean
	local numClientEventsLoaded = 0

	for _, instance in remotesFolder:GetDescendants() do
		if instance:IsA("BaseRemoteEvent") or instance:IsA("RemoteFunction") then
			numClientEventsLoaded += 1
		end
	end

	return numClientEventsLoaded == script:GetAttribute("NumRemotes") :: number
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a `Remote` that sends information to clients.
--- @param name -- The name of the `Remote`.
--- @param requiredParameterTypes -- The required types for parameters. Accepts `ClassName`, `EnumItem`, `any`, `...`, `?`, and `|`.
--- @param remoteType? -- Whether the `Remote` is unreliable, reliable, or yields and returns a value.
--- @param moduleNameOverride? -- The string to use in place of the module's name.
--- @return ServerRemote -- The new `Remote`.
--- @error Remotes cannot be created on the client -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'requiredParameterTypes' expected type '{string}', got '{typeof(requiredParameterTypes)}' -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | Unreliable" | "Reliable" | "Returns"', got '{remoteType}' -- Incorrect usage.
--- @error Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function -- Not allowed.
--- @error Remote '{name}' already created in '{moduleName}' -- Duplicate.
function Remotes.Server:CreateToClient(name: string, requiredParameterTypes: {string}, remoteType: ("Unreliable" | "Reliable" | "Returns")?, moduleNameOverride: string?): ServerRemote
	if IS_CLIENT then error("Remotes cannot be created on the client", 0) end
	if type(requiredParameterTypes) ~= "table" then error(`Remotes.CreateToClient: Parameter 'requiredParameterTypes' expected type '\{string}', got '{typeof(requiredParameterTypes)}'`, 0) end
	if remoteType ~= nil and remoteType ~= "Unreliable" and remoteType ~= "Reliable" and remoteType ~= "Returns" then error(`Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | "Unreliable" | "Reliable" | "Returns"', got '{remoteType}'`, 0) end

	local split = (debug.info(2, "s") :: string):split(".")
	local moduleName = moduleNameOverride or split[#split]

	if type(Remotes.Server[moduleName]) == "function" then error(`Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function`, 0) end
	if Remotes.Server[moduleName] and Remotes.Server[moduleName][name] then error(`Remote '{name}' already created in '{moduleName}'`, 0) end

	local environment = "[" .. moduleName .. "]"
	local serverFolder = remotesFolder:FindFirstChild(moduleName) or New.Instance("Folder", remotesFolder, moduleName)
	local remote = New.Instance(if remoteType == "Returns" then "RemoteFunction" elseif remoteType == "Unreliable" then "UnreliableRemoteEvent" else "RemoteEvent", serverFolder, name)
	local actions: any = {}

	if not Remotes.Server[moduleName] then
		Remotes.Server[moduleName] = {}
	end
	Remotes.Server[moduleName][remote.Name] = actions :: ServerRemote

	actions.Destroy = function(): ()
		if not Remotes.Server[moduleName][remote.Name] then return end
		remote:Destroy()
		Remotes.Server[moduleName][remote.Name] = nil
		script:SetAttribute("NumRemotes", (script:GetAttribute("NumRemotes") :: number? or 0) - 1)
	end

	if remoteType == "Returns" then
		actions.Fire = function(_, player: Player, ...: any)
			TypeChecker(remote, nil, requiredParameterTypes, ...)
			Print(environment, name, "Fire", ...)
			return remote:InvokeClient(player, ...)
		end
	else
		actions.Fire = function(_, players: Player | {Player}, ...: any)
			TypeChecker(remote, nil, requiredParameterTypes, ...)
			Print(environment, name, "Fire", players, ...)
			if type(players) == "table" then
				for _, player in players do
					remote:FireClient(player, ...)
				end
			else
				remote:FireClient(players, ...)
			end
		end

		actions.FireAll = function(_, ...: any)
			TypeChecker(remote, nil, requiredParameterTypes, ...)
			Print(environment, name, "FireAll", ...)
			remote:FireAllClients(...)
		end

		actions.FireAllExcept = function(_, ignorePlayer: Player, ...: any)
			TypeChecker(remote, nil, requiredParameterTypes, ...)
			Print(environment, name, "FireAllExcept", ignorePlayer, ...)
			for _, player in Players:GetPlayers() do
				if player ~= ignorePlayer then
					remote:FireClient(player, ...)
				end
			end
		end
	end

	script:SetAttribute("NumRemotes", (script:GetAttribute("NumRemotes") :: number? or 0) + 1)

	return actions
end

--- Creates a `Remote` that receives information from clients.
--- @param name -- The name of the `Remote`.
--- @param requiredParameterTypes -- The required types for parameters. Accepts `ClassName`, `EnumItem`, `any`, `...`, `?`, and `|`.
--- @param remoteType? -- Whether the `Remote` is unreliable, reliable, or yields and returns a value.
--- @param func -- The listener function to be invoked.
--- @param moduleNameOverride? -- The string to use in place of the module's name.
--- @return `ServerRemote` -- The new Remote.
--- @error Remotes cannot be created on the client -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'requiredParameterTypes' expected type '{string}', got '{typeof(requiredParameterTypes)}' -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | Unreliable" | "Reliable" | "Returns"', got '{remoteType}' -- Incorrect usage.
--- @error Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function -- Not allowed.
--- @error Remote '{name}' already created in '{moduleName}' -- Duplicate.
function Remotes.Server:CreateToServer(name: string, requiredParameterTypes: {string}, remoteType: ("Unreliable" | "Reliable" | "Returns")?, func: (Player, ...any) -> (...any)?, moduleNameOverride: string?): ServerRemote
	if IS_CLIENT then error("Remotes cannot be created on the client", 0) end
	if type(requiredParameterTypes) ~= "table" then error(`Remotes.CreateToServer: Parameter 'requiredParameterTypes' expected type '\{string}', got '{typeof(requiredParameterTypes)}'`, 0) end
	if remoteType ~= nil and remoteType ~= "Unreliable" and remoteType ~= "Reliable" and remoteType ~= "Returns" then error(`Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | "Unreliable" | "Reliable" | "Returns"', got '{remoteType}'`, 0) end
	if func ~= nil and type(func) ~= "function" then error(`Remotes.CreateToServer: Parameter 'func' expected type '(Player, ...any) -> (...any)?', got '{typeof(func)}'`, 0) end

	local split = (debug.info(2, "s") :: string):split(".")
	local moduleName = moduleNameOverride or split[#split]

	if type(Remotes.Server[moduleName]) == "function" then error(`Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function`, 0) end
	if Remotes.Server[moduleName] and Remotes.Server[moduleName][name] then error(`Remote '{name}' already created in '{moduleName}'`, 0) end

	local serverFolder = remotesFolder:FindFirstChild(moduleName) or New.Instance("Folder", remotesFolder, moduleName)
	local remote = New.Instance(if remoteType == "Returns" then "RemoteFunction" elseif remoteType == "Unreliable" then "UnreliableRemoteEvent" else "RemoteEvent", serverFolder, name)
	local actions: any = {}

	if not Remotes.Server[moduleName] then
		Remotes.Server[moduleName] = {}
	end
	Remotes.Server[moduleName][remote.Name] = actions :: ServerRemote

	local function getTypeCheckedFunction(newFunction: (Player, ...any) -> (...any))
		return function(player: Player, ...: any)
			TypeChecker(remote, player, requiredParameterTypes, ...)
			return newFunction(player, ...)
		end
	end

	actions.Destroy = function(): ()
		if not Remotes.Server[moduleName][remote.Name] then return end
		remote:Destroy()
		Remotes.Server[moduleName][remote.Name] = nil
		script:SetAttribute("NumRemotes", (script:GetAttribute("NumRemotes") :: number? or 0) - 1)
	end

	if remoteType == "Returns" then
		if func then
			remote.OnServerInvoke = getTypeCheckedFunction(func)
		end

		actions.SetListener = function(_, newFunction: (Player, ...any) -> (...any))
			remote.OnServerInvoke = getTypeCheckedFunction(newFunction)
		end
	else
		if func then
			remote.OnServerEvent:Connect(getTypeCheckedFunction(func))
		end

		actions.AddListener = function(_, newFunction: (Player, ...any) -> ()): RBXScriptConnection
			return remote.OnServerEvent:Connect(getTypeCheckedFunction(newFunction))
		end
	end

	script:SetAttribute("NumRemotes", (script:GetAttribute("NumRemotes") :: number? or 0) + 1)

	return actions
end

--- @ignore
function Remotes:Init()
	if IS_SERVER then
		remotesFolder = New.Instance("Folder", ReplicatedStorage, "__remotes")

		RunService.Heartbeat:Connect(function(_dt: number): ()
			script:SetAttribute("ServerTime", os.clock())
		end)
	else
		remotesFolder = ReplicatedStorage:WaitForChild("__remotes") :: Folder

		for _, remote in remotesFolder:GetDescendants() do
			if not (remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent") or remote:IsA("RemoteEvent")) then continue end
		
			connectEventClient(remote :: any)
		end

		remotesFolder.DescendantAdded:Connect(function(remote: Instance): ()
			if not (remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent") or remote:IsA("RemoteEvent")) then return end
		
			connectEventClient(remote :: any)
		end)

		-- Ensures Remotes all get replicated (Roblox bug)
		if workspace.StreamingEnabled then
			task.defer(Players.LocalPlayer.RequestStreamAroundAsync, Players.LocalPlayer, Vector3.zero)
		end

		while not haveClientEventsLoaded() do task.wait() end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Remotes
