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
local exampleRemote = Remotes:CreateToClient(name: string, returns: boolean?): any
local exampleRemote = Remotes:CreateToServer(name: string, returns: boolean?, func: (any) -> (any)): any

-- Server Invocation Absolute
Remotes.ExampleModule.ExampleRemote:Fire(player: Player, ...)
Remotes.ExampleModule.ExampleRemote:FireAll(...)

-- Server Invocation Shortcut
exampleRemote:Fire(player: Player, ...)
exampleRemote:FireAll(...)

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
	Fire: (self: any, value: any) -> ();
	Connect: (self: any, callback: Callback) -> ({Disconnect: () -> ()});
	Once: (self: any, callback: Callback) -> ({Disconnect: () -> ()});
	Wait: (self: any) -> (any);
}
New.TrackedVariable(Variable: any): {
	Get: (self: any) -> (any);
	Set: (self: any, value: any) -> ();
	Connect: (self: any, callback: Callback) -> ({Disconnect: () -> ()});
	Once: (self: any, callback: Callback) -> ({Disconnect: () -> ()});
	Wait: (self: any) -> (any);
}
```

# Code Snippets

## Script Boilerplate
```lua
require(game:GetService("ReplicatedStorage"):WaitForChild("Pronghorn"))

-- Global Variables
shared.Global.ExampleVariable = "Example"

-- Somewhere after assigning Global Variables
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

function ExampleModule.PlayerAdded(player: Player)
	-- Players.PlayerAdded shortcut.
end

function ExampleModule.PlayerRemoving(player: Player)
	-- Players.PlayerRemoving shortcut.
end
```

## Creating and Invoking a Remote
```lua
-- On Server

local tableCounted = Remotes:CreateToClient("TableCounted")
-- Second parameter is nil, so this Remote is non-returning.

Remotes:CreateToServer("CountTable", true, function(player: Player, tableToCount: {any})
	Remotes.ExampleServerModule.TableCounted:FireAll(player.Name) -- Absolute method
	tableCounted:FireAll(player.Name) -- Shortcut method
	return #tableToCount
end)
-- Second parameter is true, so this Remote returns.
```
```lua
-- On Client

Remotes.ExampleServerModule.TableCounted:Connect(function(playerName: string)
	Print(playerName, "requested a Table to be counted.")
end)

function ExampleClientModule:Deferred()
	Print(Remotes.ExampleServerModule:CountTable({"A", "B", "C"}))
end
```

# Games made with Pronghorn

- [NDA title #1](https://www.roblox.com/games/8875360163) - TeraBrite Games
- NDA title #2 - TeraBrite Games
- NDA title #3 - TeraBrite Games
- [ExoTech](https://www.roblox.com/games/7634484468) - Iron Stag Games
