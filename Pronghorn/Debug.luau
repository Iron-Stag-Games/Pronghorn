--!strict
--!optimize 2
--!native
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local a = if game:GetService("RunService"):IsServer() then "__s" else "__c"
if not script:GetAttribute(a) then script:SetAttribute(a, true) else error("Required Pronghorn/Debug from more than one Luau VM; please use BindableFunctions", 0) end

local Debug = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local enabledChannels: {[string]: boolean}?;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Prints content to the output.
--- @param ... -- The content to print.
--- @error '{channel}' is not a valid debug channel -- Internal error.
function Debug.Print(...: any): ()
	if not enabledChannels then return end

	local split = (debug.info(2, "s") :: string):split(".")
	local channel = split[#split]

	if enabledChannels[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if enabledChannels[channel] then
		print(`[{channel}]`, ...)
	end
end

--- Prints content to the output as a warning.
--- @param ... -- The content to print.
--- @error '{channel}' is not a valid debug channel -- Internal error.
function Debug.Warn(...: any): ()
	if not enabledChannels then return end

	local split = (debug.info(2, "s") :: string):split(".")
	local channel = split[#split]

	if enabledChannels[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if enabledChannels[channel] then
		warn(`[{channel}]`, ...)
	end
end

--- Prints content to the output as a warning with a call stack.
--- @param ... -- The content to print.
--- @error '{channel}' is not a valid debug channel -- Internal error.
function Debug.Trace(...: any): ()
	if not enabledChannels then return end

	local split = (debug.info(2, "s") :: string):split(".")
	local channel = split[#split]

	if enabledChannels[channel] == nil then error(`'{channel}' is not a valid debug channel`) end

	if enabledChannels[channel] then
		local args = {...}
		table.insert(args, `\n{debug.traceback()}`)
		warn(`[{channel}]`, table.unpack(args))
	end
end

--- @private
function Debug:SetEnabledChannels(newEnabledChannels: {[string]: boolean}): ()
	if type(newEnabledChannels) ~= "table" then error(`Debug.SetEnabledChannels: Parameter 'newEnabledChannels' expected type '\{[string]: boolean}', got {typeof(newEnabledChannels)}`, 0) end

	enabledChannels = newEnabledChannels
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Debug
