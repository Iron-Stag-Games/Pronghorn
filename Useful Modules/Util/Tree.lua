--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Tree = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Returns whether or not the Instance path exists.
--- @param instance -- The root Instance to check in.
--- @param ... -- The Names of the children to traverse.
--- @return boolean -- Whether or not the Instance path exists.
function Tree.Exists(instance: Instance, ...: string): boolean
	if instance and instance.Parent then
		for _, childName in {...} do
			local nextInstance = instance:FindFirstChild(childName)
			if nextInstance then
				instance = nextInstance
			else
				return false
			end
		end
		return true
	end
	return false
end

--- Yields until the Instance path exists.
--- @yields
--- @param instance -- The root Instance to wait in.
--- @param ... -- The Names of the children to traverse.
function Tree.Wait(instance: Instance, ...: string)
	if instance and instance.Parent then
		for _, childName in {...} do
			instance = instance:WaitForChild(childName)
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Tree
