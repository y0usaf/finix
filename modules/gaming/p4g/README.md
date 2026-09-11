# Persona 4 Golden Community Enhancement Pack

The desktop enables `user.gaming.p4g.enable`. `p4g-setup` pins CEP 13.99.4's
full offline archive, Reloaded II 1.30.3, Windows Desktop Runtime 9.0.20 (x64
and x86), and the Visual C++ redistributables. It preserves CEP's bundled mod
selection, order, and user settings. Set `user.gaming.p4g.enabledMods` to an
ordered list of mod IDs to override that selection.

```sh
nix build --no-link .#p4g-setup
nix run .#p4g-setup -- prepare  # safe while playing; prepares files outside Steam
nix run .#p4g-setup -- status
# Save and close P4G before this step:
nix run .#p4g-setup -- install
```

Setup must run as the Steam user. Steam must already have installed the game
and created its Proton prefix by launching it once. Installation refuses to run
while `P4G.exe` is active and does not stop Steam, OBS, or the desktop session.
Keep P4G closed until installation finishes. For a nonstandard Steam layout,
set `gameDirectory` and `prefixDirectory` explicitly.
System activation does not run the setup helper automatically.

The writable loader lives in `~/Games/P4G-CEP/generations`; `Games` is already
persisted on the desktop. Changing `stateDirectory` requires arranging
persistence for its new location. Each payload/configuration has its own
generation. Runtime caches and logs are writable; old generations remain for
rollback. Preparation reuses existing generations without overwriting their
runtime settings.

Installation backs up the entire P4G prefix and any managed game files under
`~/Games/P4G-CEP/backups/<timestamp>`, with installer output in `setup.log`.
It records installed runtime hashes inside the prefix, installs the x64 ASI
loader as `version.dll`, and adds the Reloaded bootstrapper. An application
specific Wine registry override enables it on the normal Steam entry, so no
Steam launch-option edits or Steam restart are needed. Foreign files at these
destinations are never overwritten. The pack expects the 64-bit game with
English text.

To return to vanilla P4G, save and close the game, then run:

```sh
nix run .#p4g-setup -- disable
```

This removes the two managed injection files. Saves, runtime installations,
mod settings and backups remain. A full prefix restore is a separate recovery
operation: copying an old prefix over a newer one can replace newer saves.

The upstream CEP guide specifies Proton 8.0-5. This integration preserves the
game's selected Proton version. On 2026-09-10, Proton Experimental successfully
initialized the loader and bound 4,809 modded files; P4G's opening rendered in
the live OBS capture. A Nix build alone does not establish game compatibility.
The desktop needed its open-file limit raised from 4,096 to 524,288. After an
interrupted first asset build, the generated `Mods/p5rpc.modloader/Cache` and
`Mods/crifs.v2.hook/Bind` directories were moved aside and rebuilt successfully.
The module raises Finit's hard limit and declares the user's soft/hard limit in
`/etc/security/limits.conf` for subsequent logins. During installation, the running Steam process's limit was raised with
`prlimit` without restarting Steam. The built desktop has not been activated
during the stream; apply it normally afterward to persist the login policy.

Sources: [CEP](https://gamebanana.com/mods/50961),
[CEP installation guide](https://p4g-deck.cep.one/install/download-and-prepare),
[Reloaded 1.30.3 ASI deployment](https://github.com/Reloaded-Project/Reloaded-II/blob/1.30.3/source/Reloaded.Mod.Launcher.Lib/Utility/AsiLoaderDeployer.cs),
[Reloaded injection methods](https://reloaded-project.github.io/Reloaded-II/InjectionMethods/).
