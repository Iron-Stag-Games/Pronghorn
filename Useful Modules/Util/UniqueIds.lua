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

type UniqueIds = {
	UnusedIds: {string};
	NumUniqueIds: number;
	NumUnusedIds: number;
	Bytes: number;
	GetNewId: (UniqueIds) -> (string);
	FreeId: (UniqueIds, string) -> ();
}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function getNewId(self: UniqueIds): string
	if self.NumUnusedIds > 0 then
		local id = table.remove(self.UnusedIds, self.NumUnusedIds) :: string
		self.NumUnusedIds -= 1
		return id
	else
		local id = string.pack("I" .. self.Bytes, self.NumUniqueIds)
		self.NumUniqueIds += 1
		return id
	end
end

local function freeId(self: UniqueIds, id: string): boolean
	if id:byte() + 1 <= self.NumUniqueIds then
		table.insert(self.UnusedIds, id)
		self.NumUnusedIds += 1
		return true
	end
	return false
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- @ignore
function UniqueIds.new(bytes: number): UniqueIds
	return {
		UnusedIds = {};
		NumUniqueIds = 0;
		NumUnusedIds = 0;
		Bytes = bytes;
		GetNewId = getNewId;
		FreeId = freeId;
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
