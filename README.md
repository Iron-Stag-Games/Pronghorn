# What is Pronghorn Framework?

Pronghorn is a performant, direct approach to Module scripting.

No Controllers or Services, just Modules and Remotes.

See [Pronghorn/init.lua](Pronghorn/init.lua) for documentation.

# How does Pronghorn compare to Knit?

**Pros**
- Require() called only in the Script and not in every Module.
- Immediate Module access with the Modules table.
- Obvious Remote behavior in both creation and invocation.
- Server-to-Client Remote batching.

**Cons**
- No automatic Remote creation using Services.
- Larger Module boilerplate.

**Preference**
- No Controller or Service structure.
- Boilerplate includes shortcuts to important objects.

##
## Join the Iron Stag Games Discord! - [discord.gg/n33vdDr](https://discord.gg/n33vdDr)
