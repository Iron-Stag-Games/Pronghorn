--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Sound = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Core
local New = require(ReplicatedStorage.Pronghorn.New)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Constants
local PART_EXPIRATION_TIME = 10

-- Objects
local tempFolder = New.Instance("Folder", SoundService, `__{if RunService:IsServer() then "Server" else "Client"}_Temp`)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Clones, plays, and returns a Sound.
--- @param source -- The Sound to clone and play.
--- @param newProperties -- A table of properties to apply to the cloned Sound.
--- @return Sound -- The cloned Sound.
function Sound:Play2D(source: Sound, newProperties: {[string]: any}?): Sound
	local newSound = source:Clone()
	if newProperties then
		for property, value in newProperties do
			(newSound :: any)[property] = value
		end
	end
	newSound.Parent = tempFolder
	newSound:Play()
	Debris:AddItem(newSound, PART_EXPIRATION_TIME)
	return newSound
end

--- Clones, plays, and returns a Sound in a BasePart.
--- @param source -- The Sound to clone and play.
--- @param parent -- The Parent for the cloned Sound after creation.
--- @param newProperties -- A table of properties to apply to the cloned Sound.
--- @return Sound -- The cloned Sound.
function Sound:PlayIn(source: Sound, parent: BasePart, newProperties: {[string]: any}?): Sound
	local newSound = source:Clone()
	if newProperties then
		for property, value in newProperties do
			(newSound :: any)[property] = value
		end
	end
	newSound.Parent = parent
	newSound:Play()
	Debris:AddItem(newSound, PART_EXPIRATION_TIME)
	return newSound
end

--- Clones, plays, and returns a Sound at a Position in Workspace.
--- @param source -- The Sound to clone and play.
--- @param position -- The Position for the cloned Sound after creation.
--- @param newProperties -- A table of properties to apply to the cloned Sound.
--- @return Sound -- The cloned Sound.
function Sound:PlayAt(source: Sound, position: Vector3, newProperties: {[string]: any}?): Sound
	local part = New.Instance("Part", tempFolder, "SoundPart", {
		Transparency = 1;
		Locked = true;
		Size = Vector3.new();
		CFrame = CFrame.new(position);
		CanCollide = false;
		CanQuery = false;
		CanTouch = false;
		Anchored = true;
	})
	Debris:AddItem(part, PART_EXPIRATION_TIME)
	return Sound:PlayIn(source, part, newProperties)
end

--- @ignore
function Sound:Init()
	for _, object in SoundService.Master:GetChildren() do
		if type(Sound[object.Name]) == "function" then error(`Indexing '{object.Name}' would overwrite a function`) end
		Sound[object.Name] = object
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Sound
