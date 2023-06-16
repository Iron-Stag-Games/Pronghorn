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

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local remotesFolder: Folder;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function connectEventClient(remote: RemoteFunction|RemoteEvent)
	local moduleName = remote.Parent and remote.Parent.Name
	local actions: any = {}
	local metaTable: any = {}

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = setmetatable(actions, metaTable)

	if remote:IsA("RemoteFunction") then

		actions.Connect = function(_, func: (...any?) -> (...any?))
			remote.OnClientInvoke = func
		end

		actions.Fire = function(_, ...: any?)
			local split: {string} = debug.info(2, "s"):split(".")
			local environment = "[" .. split[#split] .. "]"
			Print(environment, remote, "Fire", ...)
			return remote:InvokeServer(...)
		end

		metaTable.__call = function(_, context: any, ...: any?)
			if context ~= Remotes[moduleName] then error(`Must call {moduleName}:{remote.Name}() with a colon`) end
			local split: {string} = debug.info(2, "s"):split(".")
			local environment = "[" .. split[#split] .. "]"
			Print(environment, remote, "Fire", ...)
			return remote:InvokeServer(...)
		end

	elseif remote:IsA("RemoteEvent") then

		actions.Connect = function(_, func: (...any?) -> ()): RBXScriptConnection
			return remote.OnClientEvent:Connect(func)
		end

		actions.Fire = function(_, ...: any?)
			local split: {string} = debug.info(2, "s"):split(".")
			local environment = "[" .. split[#split] .. "]"
			Print(environment, remote, "Fire", ...)
			return remote:FireServer(...)
		end

		metaTable.__call = function(_, context: any, ...: any?)
			if context ~= Remotes[moduleName] then error(`Must call {moduleName}:{remote.Name}() with a colon`) end
			local split: {string} = debug.info(2, "s"):split(".")
			local environment = "[" .. split[#split] .. "]"
			Print(environment, remote, "Fire", ...)
			remote:FireServer(...)
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Remotes:CreateToClient(name: string, returns: boolean?)
	if RunService:IsClient() then error("Remotes cannot be created on the client") end

	local moduleName = tostring(getfenv(2).script)

	if type(Remotes[moduleName]) == "function" then error(`Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function`) end
	if Remotes[moduleName] and Remotes[moduleName][name] then error(`Remote '{name}' already created in '{moduleName}'`) end

	local environment = "[" .. moduleName .. "]"
	local serverFolder = remotesFolder:FindFirstChild(moduleName) or New.Instance("Folder", remotesFolder, moduleName)
	local remote = New.Instance(returns and "RemoteFunction" or "RemoteEvent", serverFolder, name)
	local actions = {}

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = actions

	if returns then
		actions.Fire = function(_, player: Player, ...: any?)
			Print(environment, name, "Fire", ...)
			return remote:InvokeClient(player, ...)
		end
	else
		actions.Fire = function(_, player: Player, ...: any?)
			Print(environment, name, "Fire", player, ...)
			remote:FireClient(player, ...)
		end

		actions.FireAll = function(_, ...: any?)
			Print(environment, name, "FireAll", ...)
			remote:FireAllClients(...)
		end

		actions.FireAllExcept = function(_, ignorePlayer: Player, ...: any?)
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

function Remotes:CreateToServer(name: string, returns: boolean?, func: any?)
	if RunService:IsClient() then error("Remotes cannot be created on the client") end

	local moduleName = tostring(getfenv(2).script)

	if type(Remotes[moduleName]) == "function" then error(`Creating remotes under the ModuleScript name '{moduleName}' would overwrite a function`) end
	if Remotes[moduleName] and Remotes[moduleName][name] then error(`Remote '{name}' already created in '{moduleName}'`) end

	local serverFolder = remotesFolder:FindFirstChild(moduleName) or New.Instance("Folder", remotesFolder, moduleName)
	local remote = New.Instance(returns and "RemoteFunction" or "RemoteEvent", serverFolder, name)
	local actions = {}

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = actions

	if returns then
		if func then
			remote.OnServerInvoke = func
		end

		actions.SetListener = function(_, newFunction: any)
			remote.OnServerInvoke = newFunction
		end
	else
		if func then
			remote.OnServerEvent:Connect(func)
		end

		actions.AddListener = function(_, newFunction: any): RBXScriptConnection
			return remote.OnServerEvent:Connect(newFunction)
		end
	end

	return actions
end

function Remotes:Init()
	if RunService:IsServer() then
		remotesFolder = New.Instance("Folder", ReplicatedStorage, "__remotes")
	else
		remotesFolder = ReplicatedStorage:WaitForChild("__remotes")

		for _, remote in remotesFolder:GetDescendants() do
			connectEventClient(remote)
		end

		remotesFolder.DescendantAdded:Connect(function(remote)
			connectEventClient(remote :: any)
		end)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Remotes
