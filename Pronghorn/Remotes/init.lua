--!strict
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Remotes = {}

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
type GenericRemote = typeof(setmetatable({} :: {
	Fire: (self: GenericRemote, players: Player | {Player}, ...any?) -> ();
	FireAll: (self: GenericRemote, ...any?) -> ();
	FireAllExcept: (self: GenericRemote, ignorePlayer: Player, ...any?) -> ();
	SetListener: (self: GenericRemote, newFunction: (Player, ...any) -> (...any)) -> ();
	AddListener: (self: GenericRemote, newFunction: (Player, ...any) -> ()) -> RBXScriptConnection;
	Connect: (self: GenericRemote, func: (...any) -> (...any)) -> ();
}, {} :: {
	__call: (self: GenericRemote, context: any, ...any?) -> ()
}))

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

local function connectEventClient(remote: RemoteFunction | UnreliableRemoteEvent | RemoteEvent)
	local moduleName: string = (remote :: any).Parent.Name
	local debugPrintText = `{moduleName}:{remote.Name}`
	local actions: any = {}
	local metaTable: any = {}

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = setmetatable(actions, metaTable) :: GenericRemote

	if remote:IsA("RemoteFunction") then

		actions.Connect = function(_, func: (...any) -> (...any))
			remote.OnClientInvoke = func
		end

		actions.Fire = function(_, ...: any?)
			Print(getEnvironment(), debugPrintText, {...})
			return remote:InvokeServer(...)
		end

		metaTable.__call = function(_, context: any, ...: any?)
			if context ~= Remotes[moduleName] then error(`Must call {moduleName}:{remote.Name}() with a colon`, 0) end
			return actions:Fire(...)
		end

	elseif remote:IsA("UnreliableRemoteEvent") or remote:IsA("RemoteEvent") then
		local lastServerTime: number;

		actions.Connect = function(_, func: (...any) -> ()): RBXScriptConnection
			return (remote :: RemoteEvent).OnClientEvent:Connect(func)
		end

		actions.Fire = function(_, ...: any?)
			if remote:IsA("UnreliableRemoteEvent") then
				local nextServerTime = script:GetAttribute("ServerTime")
				if nextServerTime == lastServerTime then return else lastServerTime = nextServerTime end
			end
			Print(getEnvironment(), debugPrintText, {...});
			(remote :: RemoteEvent):FireServer(...)
		end

		metaTable.__call = function(_, context: any, ...: any?)
			if context ~= Remotes[moduleName] then error(`Must call {moduleName}:{remote.Name}() with a colon`, 0) end
			actions:Fire(...)
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a Remote that sends information to Clients.
--- @param name -- The name of the Remote.
--- @param requiredParameterTypes -- The required types for parameters. Accepts ClassName, EnumItem, any, ..., ?, and |.
--- @param remoteType? -- Whether the Remote is unreliable, reliable, or yields and returns a value.
--- @error Remotes cannot be created on the client -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'requiredParameterTypes' expected type '{string}', got '{typeof(requiredParameterTypes)}' -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | Unreliable" | "Reliable" | "Returns"', got '{remoteType}' -- Incorrect usage.
--- @error Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function -- Not allowed.
--- @error Remote '{name}' already created in '{moduleName}' -- Duplicate.
function Remotes:CreateToClient(name: string, requiredParameterTypes: {string}, remoteType: ("Unreliable" | "Reliable" | "Returns")?)
	if RunService:IsClient() then error("Remotes cannot be created on the client", 0) end
	if type(requiredParameterTypes) ~= "table" then error(`Remotes.CreateToClient: Parameter 'requiredParameterTypes' expected type '\{string}', got '{typeof(requiredParameterTypes)}'`, 0) end
	if remoteType ~= nil and remoteType ~= "Unreliable" and remoteType ~= "Reliable" and remoteType ~= "Returns" then error(`Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | "Unreliable" | "Reliable" | "Returns"', got '{remoteType}'`, 0) end

	local split = (debug.info(2, "s") :: string):split(".")
	local moduleName = split[#split]

	if type(Remotes[moduleName]) == "function" then error(`Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function`, 0) end
	if Remotes[moduleName] and Remotes[moduleName][name] then error(`Remote '{name}' already created in '{moduleName}'`, 0) end

	local environment = "[" .. moduleName .. "]"
	local serverFolder = remotesFolder:FindFirstChild(moduleName) or New.Instance("Folder", remotesFolder, moduleName)
	local remote = New.Instance(if remoteType == "Returns" then "RemoteFunction" elseif remoteType == "Unreliable" then "UnreliableRemoteEvent" else "RemoteEvent", serverFolder, name)
	local actions = {}

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = (actions :: any) :: GenericRemote

	if remoteType == "Returns" then
		actions.Fire = function(_, player: Player, ...: any?)
			TypeChecker(remote, requiredParameterTypes, ...)
			Print(environment, name, "Fire", ...)
			return remote:InvokeClient(player, ...)
		end
	else
		actions.Fire = function(_, players: Player | {Player}, ...: any?)
			TypeChecker(remote, requiredParameterTypes, ...)
			Print(environment, name, "Fire", players, ...)
			if type(players) == "table" then
				for _, player in players do
					remote:FireClient(player, ...)
				end
			else
				remote:FireClient(players, ...)
			end
		end

		actions.FireAll = function(_, ...: any?)
			TypeChecker(remote, requiredParameterTypes, ...)
			Print(environment, name, "FireAll", ...)
			remote:FireAllClients(...)
		end

		actions.FireAllExcept = function(_, ignorePlayer: Player, ...: any?)
			TypeChecker(remote, requiredParameterTypes, ...)
			Print(environment, name, "FireAllExcept", ignorePlayer, ...)
			for _, player in Players:GetPlayers() do
				if player ~= ignorePlayer then
					remote:FireClient(player, ...)
				end
			end
		end
	end

	return actions
end

--- Creates a Remote that receives information from Clients.
--- @param name -- The name of the Remote.
--- @param requiredParameterTypes -- The required types for parameters. Accepts ClassName, EnumItem, any, ..., ?, and |.
--- @param remoteType? -- Whether the Remote is unreliable, reliable, or yields and returns a value.
--- @param func -- The listener function to be invoked.
--- @error Remotes cannot be created on the client -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'requiredParameterTypes' expected type '{string}', got '{typeof(requiredParameterTypes)}' -- Incorrect usage.
--- @error Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | Unreliable" | "Reliable" | "Returns"', got '{remoteType}' -- Incorrect usage.
--- @error Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function -- Not allowed.
--- @error Remote '{name}' already created in '{moduleName}' -- Duplicate.
function Remotes:CreateToServer(name: string, requiredParameterTypes: {string}, remoteType: ("Unreliable" | "Reliable" | "Returns")?, func: (Player, ...any) -> (...any)?)
	if RunService:IsClient() then error("Remotes cannot be created on the client", 0) end
	if type(requiredParameterTypes) ~= "table" then error(`Remotes.CreateToServer: Parameter 'requiredParameterTypes' expected type '\{string}', got '{typeof(requiredParameterTypes)}'`, 0) end
	if remoteType ~= nil and remoteType ~= "Unreliable" and remoteType ~= "Reliable" and remoteType ~= "Returns" then error(`Remotes.CreateToClient: Parameter 'remoteType' expected 'nil | "Unreliable" | "Reliable" | "Returns"', got '{remoteType}'`, 0) end
	if func ~= nil and type(func) ~= "function" then error(`Remotes.CreateToServer: Parameter 'func' expected type '(Player, ...any) -> (...any)?', got '{typeof(func)}'`, 0) end

	local split = (debug.info(2, "s") :: string):split(".")
	local moduleName = split[#split]

	if type(Remotes[moduleName]) == "function" then error(`Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function`, 0) end
	if Remotes[moduleName] and Remotes[moduleName][name] then error(`Remote '{name}' already created in '{moduleName}'`, 0) end

	local serverFolder = remotesFolder:FindFirstChild(moduleName) or New.Instance("Folder", remotesFolder, moduleName)
	local remote = New.Instance(if remoteType == "Returns" then "RemoteFunction" elseif remoteType == "Unreliable" then "UnreliableRemoteEvent" else "RemoteEvent", serverFolder, name)
	local actions = {}

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = (actions :: any) :: GenericRemote

	local function getTypeCheckedFunction(newFunction: (Player, ...any) -> (...any))
		return function(player: Player, ...: any)
			TypeChecker(remote, requiredParameterTypes, ...)
			return newFunction(player, ...)
		end
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

	return actions
end

--- @ignore
function Remotes:Init()
	if RunService:IsServer() then
		remotesFolder = New.Instance("Folder", ReplicatedStorage, "__remotes")

		RunService.Heartbeat:Connect(function(_dt: number)
			script:SetAttribute("ServerTime", tick())
		end)
	else
		remotesFolder = ReplicatedStorage:WaitForChild("__remotes") :: Folder

		for _, remote in remotesFolder:GetDescendants() do
			connectEventClient(remote :: any)
		end

		remotesFolder.DescendantAdded:Connect(function(remote)
			connectEventClient(remote :: any)
		end)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Remotes
