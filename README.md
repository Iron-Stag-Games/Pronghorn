<p align="center"><a href="https://discord.gg/n33vdDr">Join the Iron Stag Games Discord!</a></p>

# What is Pronghorn Framework?

Pronghorn is a direct approach to Module scripting that facilitates rapid development.

No Controllers or Services, just Modules and Remotes.

### Usage
- The Import() Function is used in a Script to import your Modules.
- Modules that access the framework require a header and footer. Otherwise, they must not return a Function.
- Modules as descendants of other Modules are not imported.
- Edit [Debug/EnabledChannels.lua](Pronghorn/Debug/EnabledChannels.lua) to toggle the output of Modules.

# How does Pronghorn compare to Knit?

### Pros
- Require() called only in the Script and not in every Module.
- Immediate Module access with the Modules table.
- Obvious Remote behavior in both creation and invocation.
- Server-to-Client Remote batching.

### Cons
- No automatic Remote creation using Services.
- Larger Module boilerplate.

### Preference
- No Controller or Service structure.
- Boilerplate includes shortcuts to important objects.

# Core Module Functions

## Remotes
```lua
Remotes:CreateToClient(Name: string, Returns: boolean?)
Remotes:CreateToServer(Name: string, Returns: boolean?, Function: (any) -> (any))
```

## Debug
```lua
Print(...)
Warn(...)
Trace(...)
```

## New
```lua
New.Instance(ClassName: string, Parent: Instance?, Name: string?, Properties: {[string]: any}): Instance
New.Event(): {
	Fire: (any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	ConnectOnce: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}
New.TrackedVariable(Variable: any): {
	Get: () -> (any);
	Set: (Value: any) -> ();
	Connect: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	ConnectOnce: ((any) -> ()) -> ({["Disconnect"]: () -> ()});
	Wait: () -> (any);
}
```

# Code Snippets

## Script Boilerplate
```lua
local Import, Global, Modules, Remotes, Print, Warn, Trace, New = unpack(require(game:GetService("ReplicatedStorage"):WaitForChild("Pronghorn")))

-- Somewhere after assigning Global variables
Import({
	ExampleModuleDirectory;
})
```

## Module Boilerplate
```lua
local ExampleModule = {} local Global, Modules, Remotes, Print, Warn, Trace, New

--[[
    Module Body
]]

return function(...) Global, Modules, Remotes, Print, Warn, Trace, New = ... return ExampleModule end
```

## Automated Module Functions
```lua
function ExampleModule:Init()
    -- Runs after all modules are imported. Cannot yield.
end

function ExampleModule:Deferred()
    -- Runs after all modules have initialized.
end

function ExampleModule:PlayerAdded(Player: Player)
    -- Players.PlayerAdded shortcut.
end

function ExampleModule:PlayerRemoving(Player: Player)
    -- Players.PlayerRemoving shortcut.
end
```

## Creating and Invoking a Remote
```lua
-- On Server
function ExampleServerModule:Init()
    Remotes:CreateToClient("TableCounted")
    -- Second parameter is nil, so this Remote is non-returning.

    Remotes:CreateToServer("CountTable", true, function(Player: Player, Table: {any})
        Remotes.ExampleServerModule.TableCounted:FireAll(Player.Name)
        return #Table
    end)
    -- Second parameter is true, so this Remote returns.
end

-- On Client
function ExampleClientModule:Init()
    Remotes.ExampleServerModule.TableCounted:Connect(function(PlayerName: string)
        Print(PlayerName, "requested a Table to be counted.")
    end)

    Print(Remotes.ExampleServerModule:CountTable({"A", "B", "C"}))
end
```
