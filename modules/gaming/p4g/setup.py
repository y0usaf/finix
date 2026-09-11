"""Materialize pinned P4G mods; touch the Proton prefix only on explicit install."""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".finix-new")
    temporary.write_text(json.dumps(data, indent=2) + "\n")
    temporary.replace(path)


def windows_path(path):
    return "Z:" + str(path).replace("/", "\\")


def digest(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def game_running():
    for process in Path("/proc").glob("[0-9]*/comm"):
        try:
            if process.read_text().strip().lower() == "p4g.exe":
                return True
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            pass
    return False


def require_stopped():
    if game_running():
        raise RuntimeError("P4G is running. Save and close it before installing or disabling mods.")


def configure_loader(root, game, enabled, final_root=None):
    app_file = root / "Apps/p4g.exe/AppConfig.json"
    app = read_json(app_file)
    app.update(AppLocation=windows_path(game / "P4G.exe"),
               WorkingDirectory=windows_path(game), AutoInject=False, DontInject=False)
    if enabled is not None:
        app["EnabledMods"] = enabled
        app["SortedMods"] = enabled + [name for name in app.get("SortedMods", []) if name not in enabled]
    mods = {read_json(p)["ModId"]: read_json(p)
            for p in (root / "Mods").glob("*/ModConfig.json")}
    pending, checked = list(app["EnabledMods"]), set()
    while pending:
        name = pending.pop()
        if name in checked:
            continue
        if name not in mods:
            raise RuntimeError(f"Enabled mod or dependency absent from pinned pack: {name}")
        checked.add(name)
        pending.extend(mods[name].get("ModDependencies", []))
    write_json(app_file, app)
    root = final_root or root
    return {
        "LoaderPath64": windows_path(root / "Loader/X64/Reloaded.Mod.Loader.dll"),
        "LoaderPath32": windows_path(root / "Loader/X86/Reloaded.Mod.Loader.dll"),
        "LauncherPath": windows_path(root / "Reloaded-II.exe"),
        "Bootstrapper64Path": windows_path(root / "Loader/X64/Bootstrapper/Reloaded.Mod.Loader.Bootstrapper.dll"),
        "Bootstrapper32Path": windows_path(root / "Loader/X86/Bootstrapper/Reloaded.Mod.Loader.Bootstrapper.dll"),
        "ApplicationConfigDirectory": windows_path(root / "Apps"),
        "ModConfigDirectory": windows_path(root / "Mods"),
        "ModUserConfigDirectory": windows_path(root / "User/Mods"),
        "MiscConfigDirectory": windows_path(root / "User/Misc"),
        "PluginConfigDirectory": windows_path(root / "Plugins"),
        "UsePortableMode": True,
        "FirstLaunch": False,
        "ShowConsole": False,
        "SkipWineLaunchWarning": True,
    }


def prepare(settings, state, payload, game):
    # Each declared payload/config gets its own writable generation. Old ones
    # remain available for rollback; builds and preparation never touch Steam.
    generation_settings = {k: v for k, v in settings.items() if k != "prefixDirectory"}
    key = hashlib.sha256(json.dumps(generation_settings, sort_keys=True).encode()).hexdigest()[:16]
    root = state / "generations" / key
    if not root.exists():
        root.parent.mkdir(parents=True, exist_ok=True)
        temporary = Path(tempfile.mkdtemp(prefix=".prepare-", dir=root.parent))
        try:
            subprocess.run(["cp", "-r", "--reflink=auto", str(payload / "Reloaded") + "/.", str(temporary)], check=True)
            subprocess.run(["chmod", "-R", "u+w", str(temporary)], check=True)
            # Validate the dependency closure before publishing the generation.
            loader_config = configure_loader(temporary, game, settings["enabledMods"], final_root=root)
            write_json(temporary / "ReloadedII.json", loader_config)
            (temporary / "portable.txt").touch()
            temporary.rename(root)
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)
    loader_config = read_json(root / "ReloadedII.json")
    print(f"Prepared CEP 13.99.4 + Reloaded II 1.30.3: {root}", flush=True)
    return root, loader_config


def wine(settings, arguments, log):
    env = os.environ | {"STEAM_DIR": settings["steamDirectory"], "WINEDEBUG": "-all"}
    command = ('test "$WINEPREFIX" -ef ' + shlex.quote(settings["prefixDirectory"])
               + ' || { echo "Protontricks selected a different prefix" >&2; exit 1; }; '
               + '"$WINE" ' + shlex.join(str(arg) for arg in arguments))
    result = subprocess.run(["protontricks", "-c", command, "1113000"],
                            env=env, stdout=log, stderr=subprocess.STDOUT)
    # Windows ERROR_SUCCESS_REBOOT_REQUIRED (3010) is truncated to eight bits.
    if result.returncode not in (0, 194):
        raise RuntimeError(f"Proton setup exited {result.returncode}; see {log.name}")


def install(settings, state, payload, game, prefix, root, loader_config):
    require_stopped()
    manifest_path = game / ".finix-p4g.json"
    previous = read_json(manifest_path) if manifest_path.exists() else {"files": {}}
    files = {
        "version.dll": payload / "Asi/ASILoader64.dll",
        "Reloaded.Mod.Loader.Bootstrapper.asi": root / "Loader/X64/Bootstrapper/Reloaded.Mod.Loader.Bootstrapper.dll",
    }
    for name, source in files.items():
        target = game / name
        if target.exists() and digest(target) not in (digest(source), previous["files"].get(name)):
            raise RuntimeError(f"Refusing to replace an unmanaged or modified file: {target}")
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    backup = state / "backups" / timestamp
    backup.mkdir(parents=True)
    print(f"Backing up Proton prefix to {backup / 'pfx'}", flush=True)
    subprocess.run(["cp", "-a", "--reflink=auto", str(prefix), str(backup / "pfx")], check=True)
    for name in [*files, ".finix-p4g.json"]:
        source = game / name
        if source.exists():
            target = backup / "game" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    marker = prefix / ".finix-p4g-runtimes.json"
    runtime_files = sorted((payload / "Setup").glob("*.exe"))
    wanted = {p.name: digest(p) for p in runtime_files}
    installed = read_json(marker) if marker.exists() else None
    dotnet_present = all((prefix / "drive_c" / directory /
                          "dotnet/shared/Microsoft.WindowsDesktop.App/9.0.20").is_dir()
                         for directory in ("Program Files", "Program Files (x86)"))
    log_path = backup / "setup.log"
    with log_path.open("w") as log:
        if installed != wanted or not dotnet_present:
            for installer in runtime_files:
                require_stopped()
                print(f"Installing {installer.name} (log: {log_path})", flush=True)
                wine(settings, [str(installer), "/install", "/quiet", "/norestart"], log)
            write_json(marker, wanted)
        require_stopped()
        config_path = prefix / "drive_c/users/steamuser/AppData/Roaming/Reloaded-Mod-Loader-II/ReloadedII.json"
        existing = read_json(config_path) if config_path.exists() else {}
        write_json(config_path, existing | loader_config)
        # Per-application overrides leave other programs in the prefix alone.
        key = r"HKCU\Software\Wine\AppDefaults\P4G.exe\DllOverrides"
        for dll in ("version", "msvcp140", "msvcp140_1", "msvcp140_2", "vcruntime140", "vcruntime140_1"):
            wine(settings, ["reg", "add", key, "/v", dll, "/t", "REG_SZ", "/d", "native,builtin", "/f"], log)
    require_stopped()
    # Reserve/write manifest data before publishing any injection files. A full
    # disk at this stage must not leave untracked, active injection behind.
    pending_manifest = game / ".finix-p4g.pending.json"
    write_json(pending_manifest, {"files": {n: digest(p) for n, p in files.items()},
                                  "generation": str(root), "backup": str(backup)})
    # The proxy DLL is installed last: a partially completed runtime setup must
    # never make Steam load an incomplete mod installation.
    for name in reversed(files):
        target = game / name
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name(target.name + ".finix-new")
        shutil.copyfile(files[name], temporary)
        temporary.replace(target)
    pending_manifest.replace(manifest_path)
    print("Installed. Launch Persona 4 Golden through its normal Steam entry.")


def disable(game):
    require_stopped()
    path = game / ".finix-p4g.json"
    if not path.exists():
        raise RuntimeError("No finix-managed P4G installation found.")
    manifest = read_json(path)
    for name, expected in manifest["files"].items():
        target = game / name
        if target.exists() and digest(target) != expected:
            raise RuntimeError(f"Refusing to remove a modified file: {target}")
    for name in manifest["files"]:
        (game / name).unlink(missing_ok=True)
    path.unlink()
    print("Mod injection disabled. Steam will launch vanilla P4G; backups and mod settings are retained.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("settings", type=Path)
    parser.add_argument("action", choices=["prepare", "install", "disable", "status"], nargs="?", default="install")
    args = parser.parse_args()
    settings = read_json(args.settings)
    state, payload, game = (Path(settings[k]) for k in ("stateDirectory", "payload", "gameDirectory"))
    prefix = Path(settings["prefixDirectory"])
    if args.action == "status":
        print(json.dumps({"running": game_running(), "installed": (game / '.finix-p4g.json').exists(),
                          "state": str(state), "prefix": str(prefix)}, indent=2))
        return
    if os.geteuid() == 0:
        raise RuntimeError("Run p4g-setup as your Steam user, without sudo.")
    if args.action in ("install", "disable"):
        require_stopped()
    if not (game / "P4G.exe").is_file() or not (prefix / "system.reg").is_file():
        raise RuntimeError("Install P4G in Steam and launch it once before setup.")
    state.mkdir(parents=True, exist_ok=True)
    with (state / ".setup.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if args.action == "disable":
            disable(game)
            return
        root, loader_config = prepare(settings, state, payload, game)
        if args.action == "install":
            install(settings, state, payload, game, prefix, root, loader_config)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        sys.exit(f"p4g-setup: {exc}")
