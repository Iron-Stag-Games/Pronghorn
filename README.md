[![Lua linting](https://github.com/Iron-Stag-Games/Pronghorn/actions/workflows/lua-lint.yml/badge.svg)](https://github.com/Iron-Stag-Games/Pronghorn/actions/workflows/lua-lint.yml)

```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                                         ▓███                         ║
║             ▄█▀▄▄▓█▓                   █▓█ ██                        ║
║            ▐████                         █ ██                        ║
║             ████                        ▐█ ██                        ║
║             ▀████                       ▐▌▐██                        ║
║              ▓█▌██▄                     █████                        ║
║               ▀█▄▓██▄                  ▐█████                        ║
║                ▀▓▓████▄   ▄▓        ▓▄ █████     ▓ ▌                 ║
║             ▀██████████▓  ██▄       ▓██████▓    █   ▐                ║
║                 ▀▓▓██████▌▀ ▀▄      ▐██████    ▓  █                  ║
║                    ▀███████   ▀     ███████   ▀  █▀                  ║
║                      ███████▀▄     ▓███████ ▄▓  ▄█   ▐               ║
║                       ▀████   ▀▄  █████████▄██  ▀█   ▌               ║
║                        ████      █████  ▄ ▀██    █  █                ║
║                       ██▀▀███▓▄██████▀▀▀▀▀▄▀    ▀▄▄▀                 ║
║                       ▐█ █████████ ▄██▓██ █  ▄▓▓                     ║
║                      ▄███████████ ▄████▀███▓  ███                    ║
║                    ▓███████▀  ▐     ▄▀▀▀▓██▀ ▀██▌                    ║
║                ▄▓██████▀▀▌▀   ▄        ▄▀▓█     █▌                   ║
║               ████▓▓                 ▄▓▀▓███▄   ▐█                   ║
║               ▓▓                  ▄  █▓██████▄▄███▌                  ║
║                ▄       ▌▓█     ▄██  ▄██████████████                  ║
║                   ▀▀▓▓████████▀   ▄▀███████████▀████                 ║
║                          ▀████████████████▀▓▄▌▌▀▄▓██                 ║
║                           ██████▀██▓▌▀▌ ▄     ▄▓▌▐▓█▌                ║
║                                                                      ║
║                                                                      ║
║                     Pronghorn Framework  Rev. B1                     ║
║             https://iron-stag-games.github.io/Pronghorn              ║
║                GNU Lesser General Public License v2.1                ║
║                                                                      ║
╠═════════════════════════════ Framework ══════════════════════════════╣
║                                                                      ║
║  Pronghorn is a performant, direct approach to Module scripting.     ║
║   No Clients or Services, just Modules and Remotes.                  ║
║                                                                      ║
║  All content is stored in the Global, Modules, and Remotes tables.   ║
║                                                                      ║
╠═══════════════════════════════ Script ═══════════════════════════════╣
║                                                                      ║
║  The Import() Function is used in a Script to import your Modules.   ║
║   Modules as descendants of other Modules are not imported.          ║
║                                                                      ║
╠══════════════════════════════ Modules ═══════════════════════════════╣
║                                                                      ║
║  Modules that access the framework require a header and footer.      ║
║   Otherwise, they must not return a Function.                        ║
║   See 'New.lua' for an example of a header and footer.               ║
║                                                                      ║
║  Module Functions with the following names are automated:            ║
║   - Init() - Runs after all modules are imported. Cannot yield.      ║
║   - Deferred() - Runs after all modules have initialized.            ║
║   - PlayerAdded(Player) - Players.PlayerAdded shortcut.              ║
║   - PlayerRemoving(Player) - Players.PlayerRemoving shortcut.        ║
║                                                                      ║
║  The '__unpack' flag unpacks Module data into the Modules table.     ║
║   When set, a reference to the Module will not be created.           ║
║   See 'Debug\init.lua' for an example of the __unpack flag.          ║
║                                                                      ║
╠═══════════════════════════ Remotes Module ═══════════════════════════╣
║                                                                      ║
║  The Remotes Module is used for all network communication.           ║
║   Remotes are always immediately visible on the Client.              ║
║   Remotes are grouped by the origin Module's name.                   ║
║   CreateToServer() remotes are invoked directly.                     ║
║    -> Remotes.Module:Remote()                                        ║
║   CreateToClient() remotes use Fire and FireAll.                     ║
║    -> Remotes.Module.Remote:Fire(Player)                             ║
║                                                                      ║
║  Server-to-Client remotes are batched for improved performance.      ║
║                                                                      ║
╠════════════════════════════ Debug Module ════════════════════════════╣
║                                                                      ║
║  The Debug Module is used to filter the output by Module.            ║
║   Its Functions are unpacked as the following:                       ║
║    - Modules.Print()                                                 ║
║    - Modules.Warn()                                                  ║
║    - Modules.Traceback()                                             ║
║   Edit 'Debug\EnabledChannels.lua' for output configuration.         ║
║                                                                      ║
╠═════════════════════════════ New Module ═════════════════════════════╣
║                                                                      ║
║  The New Module can be used to create Instances and Event objects.   ║
║   Event and TrackedVariable objects outperform BindableEvents.       ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```
