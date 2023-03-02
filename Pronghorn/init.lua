--!strict
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
║                    Pronghorn Framework  Rev. B14                     ║
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
║ - Modules that access the framework may require a table reference in ║
║   the header.                                                        ║
║ - Modules as descendants of other Modules are not imported.          ║
║ - Subfolder structure is included when importing                     ║
║   (e.g. Modules.Subfolder1.Subfolder2.ExampleModule)                 ║
║ - Edit 'Debug\EnabledChannels.lua' to toggle the output of Modules.  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]]

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

type Module = {
	Object: ModuleScript;
	Return: any?;
}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function addModules(allModules: {Module}, object: Instance)
	for _, child in object:GetChildren() do
		if child:IsA("ModuleScript") then
			if child ~= script then
				table.insert(allModules, {Object = child, Return = require(child) :: any})
			end
		else
			addModules(allModules, child)
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function shared.Import(paths: {Instance})
	local allModules: {Module} = {}

	for _, object in paths do
		addModules(allModules, object)
	end

	-- Init
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Init then
			local didHeartbeat;
			RunService.Heartbeat:Once(function()
				didHeartbeat = true
			end)
			moduleTable.Return:Init()
			if didHeartbeat then
				error(`{moduleTable.Object:GetFullName()} yielded during Init`)
			end
		end
	end

	-- Deferred
	local deferredComplete = shared.New.Event()
	local startWaits = 0
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Deferred then
			startWaits += 1
			task.spawn(function()
				moduleTable.Return:Deferred()
				startWaits -= 1
				if startWaits == 0 then
					deferredComplete:Fire()
				end
			end)
		end
	end

	-- PlayerAdded
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerAdded then
			Players.PlayerAdded:Connect(moduleTable.Return.PlayerAdded)
		end
	end

	-- PlayerRemoving
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerRemoving then
			Players.PlayerRemoving:Connect(moduleTable.Return.PlayerRemoving)
		end
	end

	-- Wait for Deferred Functions to complete
	while startWaits > 0 do
		deferredComplete:Wait()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

shared.Global = {}

-- Import Core Modules --

local coreModules = {}

for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") then
		table.insert(coreModules, child)
		shared[child.Name] = {}
	end
end

-- Require
for _, coreModuleObject in coreModules do
	shared[coreModuleObject.Name] = require(coreModuleObject) :: any
end

-- Init
for _, coreModuleObject in coreModules do
	local coreModule = shared[coreModuleObject.Name]
	if type(coreModule) == "table" and coreModule.Init then
		coreModule:Init()
	end
end

-- Deferred
for _, coreModuleObject in coreModules do
	local coreModule = shared[coreModuleObject.Name]
	if type(coreModule) == "table" and coreModule.Deferred then
		task.spawn(coreModule.Deferred, coreModule)
	end
end

-- Cleanup
shared.Debug = nil
table.freeze(shared)

return true
