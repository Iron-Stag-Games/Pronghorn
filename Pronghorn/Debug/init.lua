--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ENABLED_CHANNELS = require(script.EnabledChannels) :: {[string]: boolean}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function shared.Print(...)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(("'%s' is not a valid debug channel"):format(channel)) end

	if ENABLED_CHANNELS[channel] then
		print("[" .. channel .. "]", ...)
	end
end

function shared.Warn(...)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(("'%s' is not a valid debug channel"):format(channel)) end

	if ENABLED_CHANNELS[channel] then
		warn("[" .. channel .. "]", ...)
	end
end

function shared.Trace(...)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(("'%s' is not a valid debug channel"):format(channel)) end

	if ENABLED_CHANNELS[channel] then
		warn(debug.traceback("[" .. channel .. "]"), ...)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return true
