--!strict
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local Debug = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ENABLED_CHANNELS = require(script.EnabledChannels) :: {[string]: boolean}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Debug.Print(...)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if ENABLED_CHANNELS[channel] then
		print("[" .. channel .. "]", ...)
	end
end

function Debug.Warn(...)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if ENABLED_CHANNELS[channel] then
		warn("[" .. channel .. "]", ...)
	end
end

function Debug.Trace(...)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if ENABLED_CHANNELS[channel] then
		warn(debug.traceback("[" .. channel .. "]"), ...)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Debug
