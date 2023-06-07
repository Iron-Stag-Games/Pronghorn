<p align="center"><a href="https://discord.gg/n33vdDr">Join the Iron Stag Games Discord!</a></p>

# What is Pronghorn Framework?

Pronghorn is a direct approach to Module scripting that facilitates rapid development.

No Controllers or Services, just Modules and Remotes.

### Usage
- The Import() Function is used in a Script to import your Modules.
- Modules as descendants of other Modules are not imported.
- Edit [Debug/EnabledChannels.lua](Pronghorn/Debug/EnabledChannels.lua) to toggle the output of Modules.

# How does Pronghorn compare to others?

### Pros
- Luau typechecking.
- Requiring Pronghorn only in the Script and not in every Module.
- Obvious Remote behavior in both creation and invocation.
- Server-to-Client Remote batching.

### Cons
- No automatic Remote creation using Services.

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

-- Client Invocation Absolute
Remotes.ExampleModule:ExampleRemote(...)
Remotes.ExampleModule.ExampleRemote:Fire(...)

-- Client Invocation Shortcut
local exampleRemote = Remotes.ExampleModule.ExampleRemote
exampleRemote:Fire(...)
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
New.Clone(instance: Instance?, parent: Instance?, name: string?, properties: {[string]: any}?): Instance
	-- Parent, Name, and Properties optional parameters can be provided in any combination and order.
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
local Import = require(game:GetService("ReplicatedStorage").Pronghorn)

-- Global Variables
shared.ExampleVariable = "Example"

-- Somewhere after assigning global variables
Import({
	ExampleModuleDirectory;
})
```

## Module Boilerplate
```lua
local ExampleModule = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Core
local Print = require(ReplicatedStorage.Modules.Pronghorn.Debug).Print
local Warn = require(ReplicatedStorage.Modules.Pronghorn.Debug).Warn
local Trace = require(ReplicatedStorage.Modules.Pronghorn.Debug).Trace
local New = require(ReplicatedStorage.Modules.Pronghorn.New)
local Remotes = require(ReplicatedStorage.Modules.Pronghorn.Remotes)

-- Modules
local OtherExampleModule = require(ReplicatedStorage.Modules.OtherExampleModule)

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

- [NDA title #1](https://www.roblox.com/games/8875360163) - Fund For Games
- NDA title #2 - Fund For Games
- NDA title #3 - Fund For Games
- [ExoTech](https://www.roblox.com/games/7634484468) - Iron Stag Games
