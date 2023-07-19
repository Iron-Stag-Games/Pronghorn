--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Net = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Booleans

--- Packs and returns booleans.
--- @param ... -- The booleans to pack.
--- @return number -- The packed booleans.
function Net.PackBooleans(...: any): number
	local result = 0

	for _, boolean in {...} do
		result = result * 2 + if boolean then 1 else 0
	end

	return result
end

--- Unpacks and returns packed booleans.
--- @param ... -- The packed booleans to unpack.
--- @return ...boolean -- The unpacked booleans.
function Net.UnpackBooleans(value: number, numBooleans: number): ...boolean
	local booleans = {}

	for index = numBooleans - 1, 0, -1 do
		table.insert(booleans, bit32.extract(value, index, 1) ~= 0)
	end

	return unpack(booleans)
end

-- Signed Alphas ([-1, 1] 8 Bit)

--- Packs and returns floats.
--- @param ... -- The floats to pack.
--- @return ...number -- The packed floats.
function Net.PackSignedAlpha8(...: number): ...number
	local normals = {}

	for _, normal in {...} do
		table.insert(normals, math.round((normal + 1) * 127.5))
	end

	return unpack(normals)
end

--- Unpacks and returns packed floats.
--- @param ... -- The packed floats to unpack.
--- @return ...number -- The unpacked floats.
function Net.UnpackSignedAlpha8(...: number): ...number
	local normals = {}

	for _, normal in {...} do
		table.insert(normals, normal / 127.5 - 1)
	end

	return unpack(normals)
end

-- Signed Alphas ([-1, 1] 16 Bit)

--- Packs and returns floats.
--- @param ... -- The floats to pack.
--- @return ...number -- The packed floats.
function Net.PackSignedAlpha16(...: number): ...number
	local normals = {}

	for _, normal in {...} do
		table.insert(normals, math.round((normal + 1) * 32767.5))
	end

	return unpack(normals)
end

--- Unpacks and returns packed floats.
--- @param ... -- The packed floats to unpack.
--- @return ...number -- The unpacked floats.
function Net.UnpackSignedAlpha16(...: number): ...number
	local normals = {}

	for _, normal in {...} do
		table.insert(normals, normal / 32767.5 - 1)
	end

	return unpack(normals)
end

-- Unsigned Alphas ([0, 1] 8 Bit)

--- Packs and returns floats.
--- @param ... -- The floats to pack.
--- @return ...number -- The packed floats.
function Net.PackUnsignedAlpha8(...: number): ...number
	local alphas = {}

	for _, alpha in {...} do
		table.insert(alphas, math.round(alpha * 255))
	end

	return unpack(alphas)
end

--- Unpacks and returns packed floats.
--- @param ... -- The packed floats to unpack.
--- @return ...number -- The unpacked floats.
function Net.UnpackUnsignedAlpha8(...: number): ...number
	local alphas = {}

	for _, alpha in {...} do
		table.insert(alphas, alpha / 255)
	end

	return unpack(alphas)
end

-- Unsigned Alphas ([0, 1] 16 Bit)

--- Packs and returns floats.
--- @param ... -- The floats to pack.
--- @return ...number -- The packed floats.
function Net.PackUnsignedAlpha16(...: number): ...number
	local alphas = {}

	for _, alpha in {...} do
		table.insert(alphas, math.round(alpha * 65535))
	end

	return unpack(alphas)
end

--- Unpacks and returns packed floats.
--- @param ... -- The packed floats to unpack.
--- @return ...number -- The unpacked floats.
function Net.UnpackUnsignedAlpha16(...: number): ...number
	local alphas = {}

	for _, alpha in {...} do
		table.insert(alphas, alpha / 65535)
	end

	return unpack(alphas)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Net
