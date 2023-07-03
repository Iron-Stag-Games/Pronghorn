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

--- Prints content to the output.
--- @param ... -- The content to print.
function Debug.Print(...: any?)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if ENABLED_CHANNELS[channel] then
		print("[" .. channel .. "]", ...)
	end
end

--- Prints content to the output as a warning.
--- @param ... -- The content to print.
function Debug.Warn(...: any?)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if ENABLED_CHANNELS[channel] then
		warn("[" .. channel .. "]", ...)
	end
end

--- Prints content to the output as a warning with a call stack.
--- @param ... -- The content to print.
function Debug.Trace(...: any?)
	local channel = tostring(getfenv(2).script)

	if ENABLED_CHANNELS[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if ENABLED_CHANNELS[channel] then
		warn(debug.traceback("[" .. channel .. "]"), ...)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Debug
