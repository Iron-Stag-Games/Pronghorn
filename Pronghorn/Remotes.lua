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

-- Types
type Queue = {Event: BindableEvent, Parameters: {any}}

-- Defines
local remotesFolder: Folder;
local toClientBatchedRemotes: {
	[Player]: {
		Remote: RemoteEvent;
		Queue: {Queue};
	}
} = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function deepCopy(data: {[any]: any})
	for key, value in data do
		if type(value) == "table" then
			data[key] = table.clone(value)
			deepCopy(data[key])
		end
	end
end

local function setupPlayer(player: Player)
	if not toClientBatchedRemotes[player] then
		toClientBatchedRemotes[player] = {
			Remote = New.Instance("RemoteEvent", remotesFolder, player.UserId);
			Queue = {};
		}
	end
end

local function addToBatchQueue(player: Player, data: Queue)
	setupPlayer(player)
	deepCopy(data.Parameters)
	table.insert(toClientBatchedRemotes[player].Queue, data)
end

local function connectEventClient(remote: BindableEvent|RemoteEvent|RemoteFunction)
	local moduleName = remote.Parent and remote.Parent.Name
	local actions: any = {}
	local metaTable: any = {}

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = setmetatable(actions, metaTable)

	if remote:IsA("BindableEvent") then
		-- BindableEvent: To Client.

		actions.Connect = function(_, func: (any) -> (any))
			return remote.Event:Connect(func)
		end

	elseif remote:IsA("RemoteEvent") then
		-- RemoteEvent: To Server.

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

	elseif remote:IsA("RemoteFunction") then
		-- RemoteFunction: Bi-directional.

		actions.Connect = function(_, func: (any) -> (any))
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
	local remote = New.Instance(returns and "RemoteFunction" or "BindableEvent", serverFolder, name)
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
			addToBatchQueue(player, {Event = remote, Parameters = {...}})
		end

		actions.FireAll = function(_, ...: any?)
			Print(environment, name, "FireAll", ...)
			for _, player in Players:GetPlayers() do
				addToBatchQueue(player, {Event = remote, Parameters = {...}})
			end
		end

		actions.FireAllExcept = function(_, ignorePlayer: Player, ...: any?)
			Print(environment, name, "FireAllExcept", ignorePlayer, ...)
			for _, player in Players:GetPlayers() do
				if player ~= ignorePlayer then
					addToBatchQueue(player, {Event = remote, Parameters = {...}})
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

		actions.AddListener = function(_, newFunction: any)
			remote.OnServerEvent:Connect(newFunction)
		end
	end

	return actions
end

function Remotes:Init()
	if RunService:IsServer() then
		remotesFolder = New.Instance("Folder", ReplicatedStorage, "__remotes")

		Players.PlayerAdded:Connect(setupPlayer)

		Players.PlayerRemoving:Connect(function(player)
			player.AncestryChanged:Wait()

			toClientBatchedRemotes[player].Remote:Destroy()
			toClientBatchedRemotes[player] = nil
		end)

		RunService.Heartbeat:Connect(function()
			for player, data in toClientBatchedRemotes do
				if next(data.Queue) then
					data.Remote:FireClient(player, data.Queue)
				end
				table.clear(data.Queue)
			end
		end)
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

function Remotes:Deferred()
	if RunService:IsClient() then
		(remotesFolder:WaitForChild(Players.LocalPlayer.UserId) :: RemoteEvent).OnClientEvent:Connect(function(batch: {Queue})
			for _, data in batch do
				data.Event:Fire(unpack(data.Parameters))
			end
		end)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Remotes
