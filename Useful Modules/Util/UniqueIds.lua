--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local UniqueIds = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

export type UniqueIds = {
	GetNewId: (UniqueIds) -> (string);
	FreeId: (UniqueIds, string) -> (boolean);
}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- @ignore
function UniqueIds.new(bytes: number, idsInUse: {string}?): UniqueIds
	local unusedIds = {};
	local numUniqueIds = 0;
	local numUnusedIds = 0;

	if idsInUse then
		for _, id in idsInUse do
			numUniqueIds = math.max(numUniqueIds, id:byte() + 1)
		end

		for index = 1, numUniqueIds do
			local id = string.char(index - 1)
			if not table.find(idsInUse, id) then
				table.insert(unusedIds, id)
				numUnusedIds += 1
			end
		end
	end

	return {
		GetNewId = function(_self: UniqueIds): string
			if numUnusedIds > 0 then
				local id = table.remove(unusedIds, numUnusedIds) :: string
				numUnusedIds -= 1
				return id
			else
				local id = string.pack("I" .. bytes, numUniqueIds)
				numUniqueIds += 1
				return id
			end
		end;

		FreeId = function(_self: UniqueIds, id: string): boolean
			if id:byte() + 1 <= numUniqueIds then
				table.insert(unusedIds, id)
				numUnusedIds += 1
				return true
			end
			return false
		end;
	}
end

--- Returns the index of a unique ID string.
--- @param bytes -- The length of the string.
--- @param id -- The unique ID string.
--- @return number -- The index of the unique ID string.
function UniqueIds:GetIdIndex(bytes: number, id: string): number
	return string.unpack("I" .. bytes, id)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return UniqueIds
