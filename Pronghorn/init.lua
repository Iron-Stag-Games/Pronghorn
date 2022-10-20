--[[
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                                         ▓███                         ║
║             ▄█▀▄▄▓█▓                   █▓█ ██                        ║
║            ▐████                         █ ██                        ║
║             ████                        ▐█ ██                        ║
║             ▀████                       ▐▌▐██                        ║
║              ▓█▌██▄                     █████                        ║
║               ▀█▄▓██▄                  ▐█████                        ║
║                ▀▓▓████▄   ▄▓        ▓▄ █████     ▓ ▌                 ║
║             ▀██████████▓  ██▄       ▓██████▓    █   ▐                ║
║                 ▀▓▓██████▌▀ ▀▄      ▐██████    ▓  █                  ║
║                    ▀███████   ▀     ███████   ▀  █▀                  ║
║                      ███████▀▄     ▓███████ ▄▓  ▄█   ▐               ║
║                       ▀████   ▀▄  █████████▄██  ▀█   ▌               ║
║                        ████      █████  ▄ ▀██    █  █                ║
║                       ██▀▀███▓▄██████▀▀▀▀▀▄▀    ▀▄▄▀                 ║
║                       ▐█ █████████ ▄██▓██ █  ▄▓▓                     ║
║                      ▄███████████ ▄████▀███▓  ███                    ║
║                    ▓███████▀  ▐     ▄▀▀▀▓██▀ ▀██▌                    ║
║                ▄▓██████▀▀▌▀   ▄        ▄▀▓█     █▌                   ║
║               ████▓▓                 ▄▓▀▓███▄   ▐█                   ║
║               ▓▓                  ▄  █▓██████▄▄███▌                  ║
║                ▄       ▌▓█     ▄██  ▄██████████████                  ║
║                   ▀▀▓▓████████▀   ▄▀███████████▀████                 ║
║                          ▀████████████████▀▓▄▌▌▀▄▓██                 ║
║                           ██████▀██▓▌▀▌ ▄     ▄▓▌▐▓█▌                ║
║                                                                      ║
║                                                                      ║
║                     Pronghorn Framework  Rev. B1                     ║
║             https://iron-stag-games.github.io/Pronghorn              ║
║                GNU Lesser General Public License v2.1                ║
║                                                                      ║
╠═════════════════════════════ Framework ══════════════════════════════╣
║                                                                      ║
║  Pronghorn is a performant, direct approach to Module scripting.     ║
║   No Clients or Services, just Modules and Remotes.                  ║
║                                                                      ║
║  All content is stored in the Global, Modules, and Remotes tables.   ║
║                                                                      ║
╠═══════════════════════════════ Script ═══════════════════════════════╣
║                                                                      ║
║  The Import() Function is used in a Script to import your Modules.   ║
║   Modules as descendants of other Modules are not imported.          ║
║                                                                      ║
╠══════════════════════════════ Modules ═══════════════════════════════╣
║                                                                      ║
║  Modules that access the framework require a header and footer.      ║
║   Otherwise, they must not return a Function.                        ║
║   See 'New.lua' for an example of a header and footer.               ║
║                                                                      ║
║  Module Functions with the following names are automated:            ║
║   - Init() - Runs after all modules are imported. Cannot yield.      ║
║   - Deferred() - Runs after all modules have initialized.            ║
║   - PlayerAdded(Player) - Players.PlayerAdded shortcut.              ║
║   - PlayerRemoving(Player) - Players.PlayerRemoving shortcut.        ║
║                                                                      ║
║  The '__unpack' flag unpacks Module data into the Modules table.     ║
║   When set, a reference to the Module will not be created.           ║
║   See 'Debug\init.lua' for an example of the __unpack flag.          ║
║                                                                      ║
╠═══════════════════════════ Remotes Module ═══════════════════════════╣
║                                                                      ║
║  The Remotes Module is used for all network communication.           ║
║   Remotes are always immediately visible on the Client.              ║
║   Remotes are grouped by the origin Module's name.                   ║
║   CreateToServer() remotes are invoked directly.                     ║
║    -> Remotes.Module:Remote()                                        ║
║   CreateToClient() remotes use Fire and FireAll.                     ║
║    -> Remotes.Module.Remote:Fire(Player)                             ║
║                                                                      ║
║  Server-to-Client remotes are batched for improved performance.      ║
║                                                                      ║
╠════════════════════════════ Debug Module ════════════════════════════╣
║                                                                      ║
║  The Debug Module is used to filter the output by Module.            ║
║   Its Functions are unpacked as the following:                       ║
║    - Modules.Print()                                                 ║
║    - Modules.Warn()                                                  ║
║    - Modules.Traceback()                                             ║
║   Edit 'Debug\EnabledChannels.lua' for output configuration.         ║
║                                                                      ║
╠═════════════════════════════ New Module ═════════════════════════════╣
║                                                                      ║
║  The New Module can be used to create Instances and Event objects.   ║
║   Event and TrackedVariable objects outperform BindableEvents.       ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]]

local Global: any, Modules: any, Remotes: any = {}, {}, nil

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AUTOMATED_FUNCTIONS = {
	"Init";
	"Deferred";
	"PlayerAdded";
	"PlayerRemoving";
}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function AddModules(AllModules: {}, Object: Instance, CurrentPath: string?)
	for _, Child in Object:GetChildren() do
		if Child:IsA("ModuleScript") then
			if Child ~= script then
				table.insert(AllModules, {Object = Child, Path = CurrentPath})
			end
		else
			AddModules(AllModules, Child, (CurrentPath or "") .. "/" .. Child.Name:gsub("/", ""))
		end
	end
end

local function AssignModule(Path: string?, Key: string, Value: {[any]: any})
	local NewPath = Modules

	if Path then
		local SubPaths = Path:split("/")
		if #SubPaths > 1 then
			for Index = 2, #SubPaths do
				if Index > 2 or SubPaths[Index] ~= "Common" then
					if NewPath[SubPaths[Index]] ~= nil and type(NewPath[SubPaths[Index]]) ~= "table" then error(("'%s' is already assigned in the Modules table"):format(Path)) end
					if NewPath[SubPaths[Index]] == nil then
						NewPath[SubPaths[Index]] = {}
					end
					NewPath = NewPath[SubPaths[Index]]
				end
			end
		end
	end

	if NewPath[Key] ~= nil then error(("'%s' is already assigned in the Modules table"):format((Path and Path .. "/" or "") .. Key)) end
	NewPath[Key] = Value
end

local function Import(Paths: {string})

	-- Add modules --

	local AllModules: {{["Object"]: ModuleScript, ["Path"]: string}} = {}

	for _, CoreModule in script:GetChildren() do
		if CoreModule.Name == "Remotes" then
			table.insert(AllModules, 1, {Object = CoreModule, Path = nil})
		else
			table.insert(AllModules, {Object = CoreModule, Path = nil})
		end
	end

	for _, Path in Paths do
		AddModules(AllModules, Path)
	end

	-- Import --

	for _, ModuleTable in AllModules do
		local NewModule = require(ModuleTable.Object)
		if type(NewModule) == "function" then
			NewModule = NewModule(Global, Modules, Modules.Remotes)
		end

		if type(NewModule) == "table" and NewModule.__unpack then
			for Key, Value in NewModule do
				if Key ~= "__unpack" then
					if table.find(AUTOMATED_FUNCTIONS, Key) then error("The __unpack flag cannot be set on Modules with automated functions") end
					AssignModule(ModuleTable.Path, Key, Value)
				end
			end
		else
			AssignModule(ModuleTable.Path, ModuleTable.Object.Name, NewModule)
		end

		ModuleTable.Return = NewModule
	end


	-- Cleanup
	Remotes = Modules.Remotes
	Modules.Remotes = nil
	table.freeze(Modules)

	-- Init --

	for _, ModuleTable in AllModules do
		if ModuleTable.Return.Init then
			local DidHeartbeat;
			local HeartbeatConnection;
			HeartbeatConnection = RunService.Heartbeat:Connect(function()
				DidHeartbeat = true
				HeartbeatConnection:Disconnect()
			end)
			ModuleTable.Return:Init()
			if DidHeartbeat then
				error(("%s yielded during Init"):format(ModuleTable.Object:GetFullName()))
			end
		end
	end

	-- Deferred --

	local DeferredComplete = Modules.New.Event()
	local StartWaits = 0
	for _, ModuleTable in AllModules do
		if ModuleTable.Return.Deferred then
			StartWaits += 1
			task.spawn(function()
				ModuleTable.Return:Deferred()
				StartWaits -= 1
				if StartWaits == 0 then
					DeferredComplete:Fire()
				end
			end)
		end
	end

	-- PlayerAdded --

	for _, ModuleTable in AllModules do
		if ModuleTable.Return.PlayerAdded then
			Players.PlayerAdded:Connect(ModuleTable.Return.PlayerAdded)
		end
	end

	-- PlayerRemoving --

	for _, ModuleTable in AllModules do
		if ModuleTable.Return.PlayerRemoving then
			Players.PlayerRemoving:Connect(ModuleTable.Return.PlayerRemoving)
		end
	end

	-- Wait for Deferred functions to complete
	while StartWaits > 0 do
		DeferredComplete:Wait()
	end
end

return {Import, Global, Modules, Remotes}
