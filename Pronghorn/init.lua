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
║                    Pronghorn Framework  Rev. B59                     ║
║             https://github.com/Iron-Stag-Games/Pronghorn             ║
║                GNU Lesser General Public License v2.1                ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║      Pronghorn is a Roblox framework with a direct approach to       ║
║         Module scripting that facilitates rapid development.         ║
║                                                                      ║
║        No Controllers or Services, just Modules and Remotes.         ║
║                                                                      ║
╠═══════════════════════════════ Usage ════════════════════════════════╣
║                                                                      ║
║ - Pronghorn:Import() is used in a Script to import your Modules.     ║
║ - Modules as descendants of other Modules are not imported.          ║
║ - Pronghorn:SetEnabledChannels() controls the output of Modules.     ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]]

local Pronghorn = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Services
local Players = game:GetService("Players")

-- Core
local Debug = require(script.Debug)
local New = require(script.New)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Types
type Module = {
	Object: ModuleScript;
	Return: any?;
}

-- Defines
local imported = false
local startWaits = math.huge

-- Objects
local deferredComplete = New.Event()

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function addModules(allModules: {Module}, object: Instance)
	if object ~= script then
		if object:IsA("ModuleScript") then
			local alreadyAdded = false
			for _, moduleTable in allModules do
				if moduleTable.Object == object then
					alreadyAdded = true
					break
				end
			end
			if not alreadyAdded then
				table.insert(allModules, {Object = object, Return = require(object) :: any})
			end
		else
			for _, child in object:GetChildren() do
				addModules(allModules, child)
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- @todo
function Pronghorn:SetEnabledChannels(newEnabledChannels: {[string]: boolean})
	Debug:SetEnabledChannels(newEnabledChannels)
end

--- @todo
--- @yields
function Pronghorn:Import(paths: {Instance})
	if imported then
		error("Pronghorn:Import() cannot be called more than once", 0)
	end

	local allModules: {Module} = {}

	for _, object in paths do
		addModules(allModules, object)
	end

	-- Init
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Init then
			local thread = task.spawn(moduleTable.Return.Init, moduleTable.Return)
			if coroutine.status(thread) ~= "dead" then
				error(`{moduleTable.Object:GetFullName()}: Yielded during Init function`, 0)
			end
		end
	end

	-- Deferred
	startWaits = 0
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Deferred then
			startWaits += 1
			task.spawn(function()
				local running = true
				task.delay(15, function()
					if running then
						warn(`{moduleTable.Object:GetFullName()}: Infinite yield possible in Deferred function`)
					end
				end)
				moduleTable.Return:Deferred()
				running = false
				startWaits -= 1
				if startWaits == 0 then
					deferredComplete:Fire()
				end
			end)
		end
	end

	-- PlayerAdded
	local function playerAdded(player: Player)
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerAdded then
				task.spawn(moduleTable.Return.PlayerAdded, player)
			end
		end
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerAddedDeferred then
				task.spawn(moduleTable.Return.PlayerAddedDeferred, player)
			end
		end
	end
	Players.PlayerAdded:Connect(playerAdded)
	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end

	-- PlayerRemoving
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerRemoving then
				task.spawn(moduleTable.Return.PlayerRemoving, player)
			end
		end
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerRemovingDeferred then
				task.spawn(moduleTable.Return.PlayerRemovingDeferred, player)
			end
		end
	end)

	-- Wait for Deferred Functions to complete
	Pronghorn:Wait()

	imported = true
end

--- Yields until all imported module Deferred Functions have completed.
--- @yields
function Pronghorn:Wait()
	while startWaits > 0 do
		deferredComplete:Wait()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Import Core Modules --

local coreModules = {}

for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") then
		coreModules[child.Name] = require(child) :: any
	end
end

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

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Pronghorn
