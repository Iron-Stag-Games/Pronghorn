--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Remotes = shared.Remotes

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local remotesFolder;
local toClientBatchedRemotes: {
	[Player]: {
		Remote: RemoteEvent;
		Queue: {
			{
				Event: BindableEvent;
				Parameters: {any};
			}
		};
	}
} = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function setupPlayer(player: Player)
	if not toClientBatchedRemotes[player] then
		toClientBatchedRemotes[player] = {
			Remote = shared.New.Instance("RemoteEvent", remotesFolder, player.UserId);
			Queue = {};
		}
	end
end

local function addToBatchQueue(player: Player, data: {Event: BindableEvent, Parameters: {any}})
	setupPlayer(player)
	table.insert(toClientBatchedRemotes[player].Queue, data)
end

local function connectEventClient(remote: BindableEvent|RemoteEvent|RemoteFunction)
	local moduleName = remote.Parent and remote.Parent.Name
	local actions = {}
	local metaTable = {}

	if remote:IsA("BindableEvent") then
		-- BindableEvent: To Client.

		function actions:Connect(func: (any) -> (any))
			return remote.Event:Connect(func)
		end

	elseif remote:IsA("RemoteEvent") then
		-- RemoteEvent: To Server.

		function metaTable.__call(_, context, ...)
			if context ~= Remotes[moduleName] then error(("Must call %s:%s() with a colon"):format(moduleName, remote.Name)) end
			local split = debug.info(2, "s"):split(".")
			local environment = "[" .. split[#split] .. "]"
			shared.Print(environment, remote, "Fire", ...)
			remote:FireServer(...)
		end

	elseif remote:IsA("RemoteFunction") then
		-- RemoteFunction: Bi-directional.

		function actions:Connect(func: (any) -> (any))
			remote.OnClientInvoke = func
		end

		function metaTable.__call(_, context, ...)
			if context ~= Remotes[moduleName] then error(("Must call %s:%s() with a colon"):format(moduleName, remote.Name)) end
			local split = debug.info(2, "s"):split(".")
			local environment = "[" .. split[#split] .. "]"
			shared.Print(environment, remote, "Fire", ...)
			return remote:InvokeServer(...)
		end
	end

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = setmetatable(actions, metaTable)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Remotes:CreateToClient(name: string, returns: boolean?)
	if RunService:IsClient() then error("Remotes cannot be created on the client") end

	local moduleName = tostring(getfenv(2).script)

	if type(Remotes[moduleName]) == "function" then error(("Creating remotes under the ModuleScript name '%s' would overwrite a function"):format(moduleName)) end
	if Remotes[moduleName] and Remotes[moduleName][name] then error(("Remote '%s' already created in '%s'"):format(name, moduleName)) end

	local environment = "[" .. moduleName .. "]"
	local serverFolder = remotesFolder:FindFirstChild(moduleName) or shared.New.Instance("Folder", remotesFolder, moduleName)
	local remote = shared.New.Instance(returns and "RemoteFunction" or "BindableEvent", serverFolder, name)
	local actions = {}

	if returns then
		function actions:Fire(...)
			shared.Print(environment, name, "Fire", ...)
			return remote:InvokeClient(...)
		end
	else
		function actions:Fire(player, ...)
			shared.Print(environment, name, "Fire", player, ...)
			addToBatchQueue(player, {Event = remote, Parameters = {...}})
		end

		function actions:FireAll(...)
			shared.Print(environment, name, "FireAll", ...)
			for _, player in Players:GetPlayers() do
				addToBatchQueue(player, {Event = remote, Parameters = {...}})
			end
		end

		function actions:FireAllExcept(ignorePlayer, ...)
			shared.Print(environment, name, "FireAllExcept", ignorePlayer, ...)
			for _, player in Players:GetPlayers() do
				if player ~= ignorePlayer then
					addToBatchQueue(player, {Event = remote, Parameters = {...}})
				end
			end
		end
	end

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = actions
end

function Remotes:CreateToServer(name: string, returns: boolean?, func: (any) -> (any))
	if RunService:IsClient() then error("Remotes cannot be created on the client") end
	if not func then error("ToServer remotes must bind a Function") end

	local moduleName = tostring(getfenv(2).script)

	if type(Remotes[moduleName]) == "function" then error(("Creating remotes under the ModuleScript name '%s' would overwrite a function"):format(moduleName)) end
	if Remotes[moduleName] and Remotes[moduleName][name] then error(("Remote '%s' already created in '%s'"):format(name, moduleName)) end

	local serverFolder = remotesFolder:FindFirstChild(moduleName) or shared.New.Instance("Folder", remotesFolder, moduleName)
	local remote = shared.New.Instance(returns and "RemoteFunction" or "RemoteEvent", serverFolder, name)
	local actions = {}

	if returns then
		remote.OnServerInvoke = func
	else
		remote.OnServerEvent:Connect(func)

		function actions:AddListener(newFunction: (any) -> (any))
			remote.OnServerEvent:Connect(newFunction)
		end
	end

	if not Remotes[moduleName] then
		Remotes[moduleName] = {}
	end
	Remotes[moduleName][remote.Name] = actions
end

function Remotes:Init()
	if RunService:IsServer() then
		remotesFolder = shared.New.Instance("Folder", ReplicatedStorage, "__remotes")

		Players.PlayerAdded:Connect(setupPlayer)

		Players.PlayerRemoving:Connect(function(player)
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
			connectEventClient(remote)
		end)
	end
end

function Remotes:Deferred()
	if RunService:IsClient() then
		remotesFolder:WaitForChild(Players.LocalPlayer.UserId).OnClientEvent:Connect(function(batch: {{Event: BindableEvent, Parameters: {any}}})
			for _, data in batch do
				data.Event:Fire(unpack(data.Parameters))
			end
		end)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Remotes
