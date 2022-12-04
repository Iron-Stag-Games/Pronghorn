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
║                     Pronghorn Framework  Rev. B8                     ║
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

local Pronghorn = {
	Global = {};
	Modules = {};
}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local coreModules: any = {}
local coreModuleFunctions = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

local function assignModule(path: string?, key: string, value: {[any]: any})
	local newPath = Pronghorn.Modules

	if path then
		local subPaths = path:split("/")
		if #subPaths > 1 then
			for index = 2, #subPaths do
				if index > 2 or subPaths[index] ~= "Common" then
					if newPath[subPaths[index]] ~= nil and type(newPath[subPaths[index]]) ~= "table" then error(("'%s' is already assigned in the Modules table"):format(path)) end
					if newPath[subPaths[index]] == nil then
						newPath[subPaths[index]] = {}
					end
					newPath = newPath[subPaths[index]]
				end
			end
		end
	end

	if newPath[key] ~= nil then error(("'%s' is already assigned in the Modules table"):format((if path then path .. "/" else "") .. key)) end
	newPath[key] = value
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Pronghorn.Import(paths: {string})
	local allModules: {{["Object"]: ModuleScript, ["Path"]: string}} = {}

	for _, path in paths do
		addModules(allModules, path)
	end

	for _, moduleTable in allModules do
		local newModule = require(moduleTable.Object)
		if type(newModule) == "function" then
			newModule = newModule(Pronghorn.Global, Pronghorn.Modules, coreModules.Remotes, coreModules.Print, coreModules.Warn, coreModules.Trace, coreModules.New)
		end
		assignModule(moduleTable.Path, moduleTable.Object.Name, newModule)
		moduleTable.Return = newModule
	end

	-- Cleanup
	table.freeze(Pronghorn.Modules)

	-- Init
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Init then
			local didHeartbeat;
			local heartbeatConnection; heartbeatConnection = RunService.Heartbeat:Connect(function()
				didHeartbeat = true
				heartbeatConnection:Disconnect()
			end)
			moduleTable.Return:Init()
			if didHeartbeat then
				error(("%s yielded during Init"):format(moduleTable.Object:GetFullName()))
			end
		end
	end

	-- Deferred
	local deferredComplete = coreModules.New.Event()
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

-- Import Core Modules --

for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") then
		coreModuleFunctions[child.Name] = require(child)
		coreModules[child.Name] = coreModuleFunctions[child.Name]()
	end
end

-- Unpack Debug Module
coreModules.Print, coreModules.Warn, coreModules.Trace, coreModules.Debug = coreModules.Debug.Print, coreModules.Debug.Warn, coreModules.Debug.Trace, nil

-- Set globals
for Name in coreModules do
	if coreModuleFunctions[Name] then
		coreModules[Name] = coreModuleFunctions[Name](Pronghorn.Global, Pronghorn.Modules, coreModules.Remotes, coreModules.Print, coreModules.Warn, coreModules.Trace, coreModules.New)
	end
end

-- Cleanup
table.freeze(coreModules)

-- Init
for _, coreModule in coreModules do
	if type(coreModule) == "table" and coreModule.Init then
		coreModule:Init()
	end
end

-- Deferred
for _, coreModule in coreModules do
	if type(coreModule) == "table" and coreModule.Deferred then
		task.spawn(coreModule.Deferred, coreModule)
	end
end

return {Pronghorn.Import, Pronghorn.Global, Pronghorn.Modules, coreModules.Remotes, coreModules.Print, coreModules.Warn, coreModules.Trace, coreModules.New}
