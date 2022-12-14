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
║                    Pronghorn Framework  Rev. B11                     ║
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
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function createModulesMetatable(path: string)
	local data = {}
	return setmetatable(data, {
		__index = function(_, key)
			error(("'Modules%s/%s' does not exist or is unregistered"):format(path, key), 0)
		end;
		__newindex = function(_, key, value)
			rawset(data, key, value)
		end;
	})
end

local function addModules(allModules: {}, object: Instance, currentPath: string?)
	for _, child in object:GetChildren() do
		if child:IsA("ModuleScript") then
			if child ~= script then
				table.insert(allModules, {Object = child, Path = currentPath})
			end
		else
			addModules(allModules, child, (currentPath or "") .. "/" .. child.Name:gsub("/", ""))
		end
	end
end

local function assignModule(path: string?, object: ModuleScript, result: {[any]: any}?)
	local newPath = shared.Modules

	if path then
		local subPaths = path:split("/")
		if #subPaths > 1 then
			for index = 2, #subPaths do
				if rawget(newPath, subPaths[index]) ~= nil and type(newPath[subPaths[index]]) ~= "table" then error(("'%s' is already assigned in the Modules table"):format(path)) end
				if rawget(newPath, subPaths[index]) == nil then
					rawset(newPath, subPaths[index], createModulesMetatable(path))
				end
				newPath = rawget(newPath, subPaths[index])
			end
		end
	end

	if rawget(newPath, object.Name) ~= nil and not result then error(("'%s' is already assigned in the Modules table"):format((if path then path .. "/" else "") .. object.Name)) end
	if type(result) == "table" and rawget(newPath, object.Name) ~= result then error(("'%s' returned the wrong table"):format((if path then path .. "/" else "") .. object.Name)) end
	rawset(newPath, object.Name, result or {})
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function shared.Import(paths: {string})
	local allModules: {{["Object"]: ModuleScript, ["Path"]: string}} = {}

	for _, path in paths do
		addModules(allModules, path)
	end

	-- Create empty tables for early linking
	for _, moduleTable in allModules do
		assignModule(moduleTable.Path, moduleTable.Object)
	end

	-- Fill module table with actual return values
	for _, moduleTable in allModules do
		moduleTable.Return = require(moduleTable.Object)
		assignModule(moduleTable.Path, moduleTable.Object, moduleTable.Return)
	end

	-- Cleanup
	table.freeze(shared.Modules)

	-- Init
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Init then
			local didHeartbeat;
			RunService.Heartbeat:Once(function()
				didHeartbeat = true
			end)
			moduleTable.Return:Init()
			if didHeartbeat then
				error(("%s yielded during Init"):format(moduleTable.Object:GetFullName()))
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
shared.Modules = createModulesMetatable("")

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
	shared[coreModuleObject.Name] = require(coreModuleObject)
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
