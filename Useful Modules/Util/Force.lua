--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

--- Executes a function and yields until it succeeds.
--- @yields
--- @param func -- The function to execute.
--- @param ... -- The parameters to pass to the function.
--- @return ...any? -- The returns of the function.
return function(func: (...any) -> (...any), ...: any): ...any?
	local args = {...}
	local success, result
	repeat
		success, result = pcall(function()
			return func(unpack(args))
		end)
	until success or not task.wait()
	return result
end
