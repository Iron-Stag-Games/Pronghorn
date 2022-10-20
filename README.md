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
║                     Pronghorn Framework  Rev. B3                     ║
║             https://iron-stag-games.github.io/Pronghorn              ║
║                GNU Lesser General Public License v2.1                ║
║                                                                      ║
╠═════════════════════════════ Framework ══════════════════════════════╣
║                                                                      ║
║  Pronghorn is a performant, direct approach to Module scripting.     ║
║   No Controllers or Services, just Modules and Remotes.              ║
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
║                                                                      ║
║  Module Functions with the following names are automated:            ║
║   - Init() - Runs after all modules are imported. Cannot yield.      ║
║   - Deferred() - Runs after all modules have initialized.            ║
║   - PlayerAdded(Player) - Players.PlayerAdded shortcut.              ║
║   - PlayerRemoving(Player) - Players.PlayerRemoving shortcut.        ║
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
║    - Print()                                                         ║
║    - Warn()                                                          ║
║    - Trace()                                                         ║
║   Edit 'Debug\EnabledChannels.lua' for output configuration.         ║
║                                                                      ║
╠═════════════════════════════ New Module ═════════════════════════════╣
║                                                                      ║
║  The New Module can be used to create Instances and Event objects.   ║
║   Event and TrackedVariable objects outperform BindableEvents.       ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```
