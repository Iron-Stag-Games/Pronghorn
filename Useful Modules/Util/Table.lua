--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Table = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Copies and returns a Table and all of its descendants.
--- @param tableToCopy -- The Table to copy.
--- @return {[any]: any} -- The copied Table.
function Table.DeepCopy(tableToCopy: {[any]: any}): {[any]: any}
	local copy = {}
	for key, value in tableToCopy do
		copy[key] = if type(value) == "table" then tableToCopy.DeepCopy(value) else value
	end
	return copy
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Table
