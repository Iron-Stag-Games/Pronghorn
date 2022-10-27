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
║                     Pronghorn Framework  Rev. B6                     ║
║             https://github.com/Iron-Stag-Games/Pronghorn             ║
║                GNU Lesser General Public License v2.1                ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║          Pronghorn is a direct approach to Module scripting          ║
║                 that facilitates rapid development.                  ║
║                                                                      ║
║        No Controllers or Services, just Modules and Remotes.         ║
║                                                                      ║
╠═══════════════════════════════ Usage ════════════════════════════════╣
║                                                                      ║
║ - The Import() Function is used in a Script to import your Modules.  ║
║ - Modules that access the framework require a header and footer.     ║
║   Otherwise, they must not return a Function.                        ║
║ - Modules as descendants of other Modules are not imported.          ║
║ - Edit 'Debug\EnabledChannels.lua' to toggle the output of Modules.  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]]

local Global, Modules = {}, {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CoreModules: any = {}
local CoreModuleFunctions = {}

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
	local AllModules: {{["Object"]: ModuleScript, ["Path"]: string}} = {}

	for _, Path in Paths do
		AddModules(AllModules, Path)
	end

	for _, ModuleTable in AllModules do
		local NewModule = require(ModuleTable.Object)
		if type(NewModule) == "function" then
			NewModule = NewModule(Global, Modules, CoreModules.Remotes, CoreModules.Print, CoreModules.Warn, CoreModules.Trace, CoreModules.New)
		end
		AssignModule(ModuleTable.Path, ModuleTable.Object.Name, NewModule)
		ModuleTable.Return = NewModule
	end

	-- Cleanup
	table.freeze(Modules)

	-- Init
	for _, ModuleTable in AllModules do
		if type(ModuleTable.Return) == "table" and ModuleTable.Return.Init then
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

	-- Deferred
	local DeferredComplete = CoreModules.New.Event()
	local StartWaits = 0
	for _, ModuleTable in AllModules do
		if type(ModuleTable.Return) == "table" and ModuleTable.Return.Deferred then
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

	-- PlayerAdded
	for _, ModuleTable in AllModules do
		if type(ModuleTable.Return) == "table" and ModuleTable.Return.PlayerAdded then
			Players.PlayerAdded:Connect(ModuleTable.Return.PlayerAdded)
		end
	end

	-- PlayerRemoving
	for _, ModuleTable in AllModules do
		if type(ModuleTable.Return) == "table" and ModuleTable.Return.PlayerRemoving then
			Players.PlayerRemoving:Connect(ModuleTable.Return.PlayerRemoving)
		end
	end

	-- Wait for Deferred Functions to complete
	while StartWaits > 0 do
		DeferredComplete:Wait()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Import Core Modules --

for _, Child in script:GetChildren() do
	CoreModuleFunctions[Child.Name] = require(Child)
	CoreModules[Child.Name] = CoreModuleFunctions[Child.Name]()
end

-- Unpack Debug Module
CoreModules.Print, CoreModules.Warn, CoreModules.Trace, CoreModules.Debug = CoreModules.Debug.Print, CoreModules.Debug.Warn, CoreModules.Debug.Trace, nil

-- Set globals
for Name in CoreModules do
	if CoreModuleFunctions[Name] then
		CoreModules[Name] = CoreModuleFunctions[Name](Global, Modules, CoreModules.Remotes, CoreModules.Print, CoreModules.Warn, CoreModules.Trace, CoreModules.New)
	end
end

-- Cleanup
table.freeze(CoreModules)

-- Init
for _, CoreModule in CoreModules do
	if type(CoreModule) == "table" and CoreModule.Init then
		CoreModule:Init()
	end
end

-- Deferred
for _, CoreModule in CoreModules do
	if type(CoreModule) == "table" and CoreModule.Deferred then
		task.spawn(CoreModule.Deferred, CoreModule)
	end
end

return {Import, Global, Modules, CoreModules.Remotes, CoreModules.Print, CoreModules.Warn, CoreModules.Trace, CoreModules.New}
