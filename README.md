# What is Pronghorn Framework?

Pronghorn is a Roblox framework with a direct approach to Module scripting that facilitates rapid development.

## Usage
- Pronghorn:Import() is used in a Script to import your Modules.
- Modules as descendants of other Modules are not imported.
- Pronghorn:SetEnabledChannels() controls the output of Modules.

# How does Pronghorn compare to others?

### Pros
- Luau typechecking and autocomplete.
- Obvious and concise error stack traces.
- Requiring Pronghorn only in the Script and not in every Module.
- Obvious Remote behavior in both creation and invocation.
- Addition of Event, QueuedEvent, and TrackedVariable.

### Cons
- No automatic Remote creation using Services.
- No Remote packing optimization techniques (due to [ordering breakage](https://en.wikipedia.org/wiki/Out-of-order_delivery).)

### Preference
- No Controller or Service structure.
- Not Promise based.

# Core Module Functions

## Debug
```luau
Print(...)
Warn(...)
Trace(...)
```

## New
```luau
New.Children(parent: Instance, children: {Instance}?): ()
New.Event(): Event<T...> = {
	Fire: (self: Event<T...>, T...) -> ();
	Connect: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Once: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Wait: (self: Event<T...>, timeout: number?) -> (boolean, T...);
	DisconnectAll: (self: Event<T...>) -> ();
}
New.QueuedEvent(): Event<T...> = {
	Fire: (self: Event<T...>, T...) -> ();
	Connect: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Once: (self: Event<T...>, callback: Callback<T...>) -> (Connection);
	Wait: (self: Event<T...>, timeout: number?) -> (boolean, T...);
	DisconnectAll: (self: Event<T...>) -> ();
}
New.TrackedVariable(variable: any): TrackedVariable<T> = {
	Get: (self: TrackedVariable<T>) -> (T);
	Set: (self: TrackedVariable<T>, value: T) -> ();
	Connect: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Once: (self: TrackedVariable<T>, callback: Callback<T, T>) -> (Connection);
	Wait: (self: TrackedVariable<T>, timeout: number?) -> (boolean, T, T);
	WaitFor: (self: TrackedVariable<T>, value: T, timeout: number?) -> (boolean, T, T);
	DisconnectAll: (self: TrackedVariable<T>) -> ();
}
New.ServerInstanceStream(players: Player | {Player}, instances: {Instance}, exclusive: boolean?): (string, {[Player]: Instance}?, {[Player]: {any}}?)
New.ClientInstanceStream(uid: string): (Event<T...>, Event<U>, Instance)
```

## Remotes
```luau
-- Creation
local exampleRemote = Remotes.Server:CreateToClient(name: string, requiredParameterTypes: {string}, remoteType: ("Unreliable" | "Reliable" | "Returns")?): any
local exampleRemote = Remotes.Server:CreateToServer(name: string, requiredParameterTypes: {string}, remoteType: ("Unreliable" | "Reliable" | "Returns")?, func: (Player, ...any) -> (...any)?): any

-- Server Invocation Absolute
Remotes.Server.ExampleModule.ExampleRemote:Fire(players: Player | {Player}, ...)
Remotes.Server.ExampleModule.ExampleRemote:FireAll(...)
Remotes.Server.ExampleModule.ExampleRemote:FireAllExcept(ignorePlayer: Player, ....)

-- Server Invocation Shortcut
exampleRemote:Fire(players: Player | {Player}, ...)
exampleRemote:FireAll(...)
exampleRemote:FireAllExcept(ignorePlayer: Player, ....)

-- Client Invocation Absolute
Remotes.Client.ExampleModule:ExampleRemote(...)
Remotes.Client.ExampleModule.ExampleRemote:Fire(...)

-- Client Invocation Shortcut
local exampleRemote = Remotes.Client.ExampleModule.ExampleRemote
exampleRemote:Fire(...)
```

# Code Snippets

## Script Boilerplate
```luau
local Pronghorn = require(game:GetService("ReplicatedStorage").Pronghorn)
Pronghorn:SetEnabledChannels({
	Remotes = false;
	ExampleModule = true;
})

-- Global Variables
shared.ExampleVariable = "Example"

-- Somewhere after assigning global variables
Pronghorn:Import({
	ExampleModuleDirectory;
})
```

## Module Boilerplate
```luau
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
```luau
function ExampleModule:Init(): ()
	-- Runs after all modules are imported. Cannot yield.
end

function ExampleModule:Deferred(): ()
	-- Runs after all modules have initialized.
end

function ExampleModule.PlayerAdded(player: Player): ()
	-- Players.PlayerAdded shortcut.
end

function ExampleModule.PlayerAddedDeferred(player: Player): ()
	-- Players.PlayerAdded shortcut. Runs after all PlayerAdded functions.
end

function ExampleModule.PlayerRemoving(player: Player): ()
	-- Players.PlayerRemoving shortcut.
end

function ExampleModule.PlayerRemovingDeferred(player: Player): ()
	-- Players.PlayerRemoving shortcut. Runs after all PlayerRemoving functions.
end
```

## Creating and Invoking a Remote
```luau
-- On Server

local tableCounted = Remotes.Server:CreateToClient("TableCounted", {"string"})
-- Third parameter is nil, so this Remote's type is "Reliable" by default.

Remotes.Server:CreateToServer("CountTable", {"table"}, "Returns", function(player: Player, tableToCount: {any}): ()
	Remotes.Server.ExampleServerModule.TableCounted:FireAll(player.Name) -- Absolute method
	tableCounted:FireAll(player.Name) -- Shortcut method
	return #tableToCount
end)
```
```luau
-- On Client

function ExampleClientModule:Deferred(): ()
	Remotes.Client.ExampleServerModule.TableCounted:Connect(function(playerName: string)
		Print(playerName, "requested a Table to be counted.")
	end)

	Print(Remotes.Client.ExampleServerModule:CountTable({"A", "B", "C"}))
end
```

# Useful Modules

https://github.com/Iron-Stag-Games/Useful-Modules

A collection of useful modules compatible with the Pronghorn Framework.

# Games made with Pronghorn

- **[Claw Machine Simulator](https://www.roblox.com/games/6891812658)** - RB Battles Games
- **[ExoTech](https://www.roblox.com/games/7634484468)** - Iron Stag Games
- **[Mansion Tycoon](https://www.roblox.com/games/12912731475)** - Capybara's Productions
- **[RB Battles](https://www.roblox.com/games/5036207802)** - RB Battles Games
- **[Traitor Town](https://www.roblox.com/games/255236425)** - Traitor Town
