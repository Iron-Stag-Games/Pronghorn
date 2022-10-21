--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Remotes = {} local Global, Modules, Print, Warn, Trace, New = nil, nil, nil, nil, nil, nil -- Core Module boilerplate only. Do not use!

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RemotesFolder;
local ToClientBatchedRemotes: {
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

local function SetupPlayer(Player: Player)
	if not ToClientBatchedRemotes[Player] then
		ToClientBatchedRemotes[Player] = {
			Remote = New.Instance("RemoteEvent", RemotesFolder, Player.UserId);
			Queue = {};
		}
	end
end

local function AddToBatchQueue(Player: Player, Data: {Event: BindableEvent, Parameters: {any}})
	SetupPlayer(Player)
	table.insert(ToClientBatchedRemotes[Player].Queue, Data)
end

local function ConnectEventClient(Remote: BindableEvent|RemoteEvent|RemoteFunction)
	local ModuleName = Remote.Parent and Remote.Parent.Name
	local Actions = {}
	local MetaTable = {}

	if Remote:IsA("BindableEvent") then
		-- BindableEvent: To Client.

		function Actions:Connect(Function: (any) -> (any))
			return Remote.Event:Connect(Function)
		end

	elseif Remote:IsA("RemoteEvent") then
		-- RemoteEvent: To Server.

		function MetaTable.__call(_, Context, ...)
			if Context ~= Remotes[ModuleName] then error(("Must call %s:%s() with a colon"):format(ModuleName, Remote.Name)) end
			local Split = debug.info(2, "s"):split(".")
			local Environment = "[" .. Split[#Split] .. "]"
			Print(Environment, Remote, "Fire", ...)
			Remote:FireServer(...)
		end

	elseif Remote:IsA("RemoteFunction") then
		-- RemoteFunction: Bi-directional.

		function Actions:Connect(Function: (any) -> (any))
			Remote.OnClientInvoke = Function
		end

		function MetaTable.__call(_, Context, ...)
			if Context ~= Remotes[ModuleName] then error(("Must call %s:%s() with a colon"):format(ModuleName, Remote.Name)) end
			local Split = debug.info(2, "s"):split(".")
			local Environment = "[" .. Split[#Split] .. "]"
			Print(Environment, Remote, "Fire", ...)
			return Remote:InvokeServer(...)
		end
	end

	if not Remotes[ModuleName] then
		Remotes[ModuleName] = {}
	end
	Remotes[ModuleName][Remote.Name] = setmetatable(Actions, MetaTable)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Remotes:CreateToClient(Name: string, Returns: boolean?)
	if RunService:IsClient() then error("Remotes cannot be created on the client") end

	local Split = debug.info(2, "s"):split(".")
	local ModuleName = Split[#Split]

	if type(Remotes[ModuleName]) == "function" then error(("Creating remotes under the ModuleScript name '%s' would overwrite a function"):format(ModuleName)) end
	if Remotes[ModuleName] and Remotes[ModuleName][Name] then error(("Remote '%s' already created in '%s'"):format(Name, ModuleName)) end

	local Environment = "[" .. ModuleName .. "]"
	local ServerFolder = RemotesFolder:FindFirstChild(ModuleName) or New.Instance("Folder", RemotesFolder, ModuleName)
	local Remote = New.Instance(Returns and "RemoteFunction" or "BindableEvent", ServerFolder, Name)
	local Actions = {}

	if Returns then
		function Actions:Fire(...)
			Print(Environment, Name, "Fire", ...)
			return Remote:InvokeClient(...)
		end
	else
		function Actions:Fire(Player, ...)
			Print(Environment, Name, "Fire", Player, ...)
			AddToBatchQueue(Player, {Event = Remote, Parameters = {...}})
		end

		function Actions:FireAll(...)
			Print(Environment, Name, "FireAll", ...)
			for _, Player in Players:GetPlayers() do
				AddToBatchQueue(Player, {Event = Remote, Parameters = {...}})
			end
		end

		function Actions:FireAllExcept(IgnorePlayer, ...)
			Print(Environment, Name, "FireAllExcept", IgnorePlayer, ...)
			for _, Player in Players:GetPlayers() do
				if Player ~= IgnorePlayer then
					AddToBatchQueue(Player, {Event = Remote, Parameters = {...}})
				end
			end
		end
	end

	if not Remotes[ModuleName] then
		Remotes[ModuleName] = {}
	end
	Remotes[ModuleName][Remote.Name] = Actions
end

function Remotes:CreateToServer(Name: string, Returns: boolean?, Function: (any) -> (any))
	if RunService:IsClient() then error("Remotes cannot be created on the client") end
	if not Function then error("ToServer remotes must bind a Function") end

	local Split = debug.info(2, "s"):split(".")
	local ModuleName = Split[#Split]

	if type(Remotes[ModuleName]) == "function" then error(("Creating remotes under the ModuleScript name '%s' would overwrite a function"):format(ModuleName)) end
	if Remotes[ModuleName] and Remotes[ModuleName][Name] then error(("Remote '%s' already created in '%s'"):format(Name, ModuleName)) end

	local ServerFolder = RemotesFolder:FindFirstChild(ModuleName) or New.Instance("Folder", RemotesFolder, ModuleName)
	local Remote = New.Instance(Returns and "RemoteFunction" or "RemoteEvent", ServerFolder, Name)
	local Actions = {}

	if Returns then
		Remote.OnServerInvoke = Function
	else
		Remote.OnServerEvent:Connect(Function)

		function Actions:AddListener(NewFunction: (any) -> (any))
			Remote.OnServerEvent:Connect(NewFunction)
		end
	end

	if not Remotes[ModuleName] then
		Remotes[ModuleName] = {}
	end
	Remotes[ModuleName][Remote.Name] = Actions
end

function Remotes:Init()
	if RunService:IsServer() then
		RemotesFolder = New.Instance("Folder", ReplicatedStorage, "__remotes")

		Players.PlayerAdded:Connect(SetupPlayer)

		Players.PlayerRemoving:Connect(function(Player)
			ToClientBatchedRemotes[Player].Remote:Destroy()
			ToClientBatchedRemotes[Player] = nil
		end)

		RunService.Heartbeat:Connect(function()
			for Player, Data in ToClientBatchedRemotes do
				if next(Data.Queue) then
					Data.Remote:FireClient(Player, Data.Queue)
				end
				table.clear(Data.Queue)
			end
		end)
	else
		RemotesFolder = ReplicatedStorage:WaitForChild("__remotes")

		for _, Remote in RemotesFolder:GetDescendants() do
			ConnectEventClient(Remote)
		end

		RemotesFolder.DescendantAdded:Connect(function(Remote)
			ConnectEventClient(Remote)
		end)
	end
end

function Remotes:Deferred()
	if RunService:IsClient() then
		RemotesFolder:WaitForChild(Players.LocalPlayer.UserId).OnClientEvent:Connect(function(Batch: {{Event: BindableEvent, Parameters: {any}}})
			for _, Data in Batch do
				Data.Event:Fire(unpack(Data.Parameters))
			end
		end)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return function(A, B, _, D, E, F, G) Global, Modules, Print, Warn, Trace, New = A, B, D, E, F, G return Remotes end -- Core Module boilerplate only. Do not use!
