--!strict
--[[
╔═══════════════════════════════════════════════╗
║       Included With Pronghorn Framework       ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

--- Executes a function in a new thread until it succeeds.
--- @param func -- The function to execute.
--- @param ... -- The parameters to pass to the function.
return function(func: (...any) -> (...any), ...: any)
	local args = {...}
	task.spawn(function()
		while not pcall(function()
			func(unpack(args))
		end) do task.wait() end
	end)
end
