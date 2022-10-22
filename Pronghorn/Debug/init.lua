--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Debug = {} local Global, Modules, Remotes, New -- Core Module boilerplate only. Do not use!

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ENABLED_CHANNELS = require(script.EnabledChannels) :: {[string]: boolean}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Debug.Print(...)
	local Split = debug.info(2, "s"):split(".")
	local Channel = Split[#Split]

	if ENABLED_CHANNELS[Channel] == nil then error(("'%s' is not a valid debug channel"):format(Channel)) end

	if ENABLED_CHANNELS[Channel] then
		print("[" .. Channel .. "]", ...)
	end
end

function Debug.Warn(...)
	local Split = debug.info(2, "s"):split(".")
	local Channel = Split[#Split]

	if ENABLED_CHANNELS[Channel] == nil then error(("'%s' is not a valid debug channel"):format(Channel)) end

	if ENABLED_CHANNELS[Channel] then
		warn("[" .. Channel .. "]", ...)
	end
end

function Debug.Trace(...)
	local Split = debug.info(2, "s"):split(".")
	local Channel = Split[#Split]

	if ENABLED_CHANNELS[Channel] == nil then error(("'%s' is not a valid debug channel"):format(Channel)) end

	if ENABLED_CHANNELS[Channel] then
		warn(debug.traceback("[" .. Channel .. "]"), ...)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return function(A, B, C, _, _, _, G) Global, Modules, Remotes, New = A, B, C, G return Debug end -- Core Module boilerplate only. Do not use!
