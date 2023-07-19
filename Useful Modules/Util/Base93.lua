--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Base93 = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local B93_ENCODE = " !#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~"

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Converts and returns an integer to a Base 93 string.
--- @param int -- The integer to convert.
--- @param length -- The length of the returned string.
--- @return string -- The converted Base 93 string.
function Base93.IntToB93(int: number, length: number): string
	if int >= 93 ^ length then error(`{int} exceeds maximum value of {93 ^ length - 1}`) end

	local digits = ""

	while int > 0 do
		local index = int % 93 + 1
		digits = B93_ENCODE:sub(index, index) .. digits
		int = math.floor(int / 93)
	end

	return string.rep(" ", length - #digits) .. digits
end

--- Converts and returns a Base 93 string to an integer.
--- @param b93 -- The Base 93 string to convert.
--- @return number -- The converted integer.
function Base93.B93ToInt(b93: string): number
	local int = 0
	local length = #b93

	for index = length, 1, -1 do
		int += (B93_ENCODE:find(b93:sub(index, index), 1, true) :: number - 1) * math.pow(93, length - index)
	end

	return int
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Base93
