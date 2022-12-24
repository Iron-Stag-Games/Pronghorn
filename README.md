<p align="center"><a href="https://discord.gg/n33vdDr">Join the Iron Stag Games Discord!</a></p>

# What is Pronghorn Framework?

Pronghorn is a direct approach to Module scripting that facilitates rapid development.

No Controllers or Services, just Modules and Remotes.

### Usage
- The Import() Function is used in a Script to import your Modules.
- Modules that access the framework may require a table reference in the header.
- Modules as descendants of other Modules are not imported.
- Subfolder structure is included when importing (e.g. Modules.Subfolder1.Subfolder2.ExampleModule)
- Edit [Debug/EnabledChannels.lua](Pronghorn/Debug/EnabledChannels.lua) to toggle the output of Modules.

# How does Pronghorn compare to others?

### Pros
- Require() called only in the Script and not in every Module.
- Immediate framework access with the shared table.
- Obvious Remote behavior in both creation and invocation.
- Server-to-Client Remote batching.

### Cons
- No automatic Remote creation using Services.
- Use of the shared table may cause interference.

### Preference
- No Controller or Service structure.

# Core Module Functions

## Remotes
```lua
-- Creation
Remotes:CreateToClient(name: string, returns: boolean?)
Remotes:CreateToServer(name: string, returns: boolean?, func: (any) -> (any))

-- Server Invocation
Remotes.ExampleModule.ExampleRemote:Fire(player: Player, ...)
Remotes.ExampleModule.ExampleRemote:FireAll(...)

-- Client Invocation
Remotes.ExampleModule:ExampleRemote(...)
```

## Debug
```lua
Print(...)
Warn(...)
Trace(...)
```

## New
```lua
New.Instance(className: string, parent: Instance?, name: string?, properties: {[string]: any}?): Instance
	-- Parent, Name, and Properties optional parameters can be provided in any combination and order.
	-- Ex. New.Instance("Part", {Properties})
New.Event(): {
	Fire: (any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Once: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}
New.TrackedVariable(Variable: any): {
	Get: () -> (any);
	Set: (value: any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Once: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}
```

# Code Snippets

## Script Boilerplate
```lua
require(game:GetService("ReplicatedStorage"):WaitForChild("Pronghorn"))

-- Somewhere after assigning Global variables
shared.Import({
	ExampleModuleDirectory;
})
```

## Module Boilerplate
```lua
local ExampleModule = shared.Modules.ExampleModule

-- Core
local Print = shared.Print
local Warn = shared.Warn
local Trace = shared.Trace
local New = shared.New
local Remotes = shared.Remotes
local Global = shared.Global

-- Modules
local OtherExampleModule = shared.Modules.OtherExampleModule

--[[
	Module Body
]]

return ExampleModule
```

## Automated Module Functions
```lua
function ExampleModule:Init()
	-- Runs after all modules are imported. Cannot yield.
end

function ExampleModule:Deferred()
	-- Runs after all modules have initialized.
end

function ExampleModule.PlayerAdded(Player: Player)
	-- Players.PlayerAdded shortcut.
end

function ExampleModule.PlayerRemoving(Player: Player)
	-- Players.PlayerRemoving shortcut.
end
```

## Creating and Invoking a Remote
```lua
-- On Server
function ExampleServerModule:Init()
	Remotes:CreateToClient("TableCounted")
	-- Second parameter is nil, so this Remote is non-returning.

	Remotes:CreateToServer("CountTable", true, function(player: Player, tableToCount: {any})
		Remotes.ExampleServerModule.TableCounted:FireAll(player.Name)
		return #tableToCount
	end)
	-- Second parameter is true, so this Remote returns.
end

-- On Client
function ExampleClientModule:Init()
	Remotes.ExampleServerModule.TableCounted:Connect(function(playerName: string)
		Print(playerName, "requested a Table to be counted.")
	end)

	Print(Remotes.ExampleServerModule:CountTable({"A", "B", "C"}))
end
```

# Games made with Pronghorn

- [RB Battles](https://www.roblox.com/games/5036207802) - TeraBrite Games
- [NDA title #1](https://www.roblox.com/games/8875360163) - TeraBrite Games
- NDA title #2 - TeraBrite Games
- [ExoTech](https://www.roblox.com/games/7634484468) - Iron Stag Games
