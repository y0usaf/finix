from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlsplit


class ShipError(RuntimeError):
    pass


def command_text(argv: list[str]) -> str:
    return shlex.join(argv)


def run(
    argv: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    process = subprocess.run(
        argv,
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and process.returncode != 0:
        detail = process.stderr.strip() or process.stdout.strip() or "no output"
        raise ShipError(
            f"command failed ({process.returncode}): {command_text(argv)}\n{detail}"
        )
    return process


def run_live(
    argv: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None
) -> None:
    process = subprocess.run(argv, cwd=cwd, env=env)
    if process.returncode != 0:
        raise ShipError(f"command failed ({process.returncode}): {command_text(argv)}")


def git(
    source: Path, *args: str, check: bool = True
) -> subprocess.CompletedProcess[str]:
    return run(["git", "-C", str(source), *args], check=check)


def normalize_path(path: str) -> str:
    clean = unquote(path).strip().strip("/")
    if clean.lower().endswith(".git"):
        clean = clean[:-4]
    return clean.casefold()


def remote_key(raw_url: str, *, relative_to: Path | None = None) -> str | None:
    raw = raw_url.strip()
    if not raw:
        return None

    for prefix, host in (("github:", "github.com"), ("gitlab:", "gitlab.com")):
        if raw.startswith(prefix):
            path = raw[len(prefix) :].split("?", 1)[0].split("#", 1)[0]
            return f"remote:{host}/{normalize_path(path)}"

    if "://" in raw:
        parsed = urlsplit(raw)
        if parsed.scheme == "file":
            return f"path:{Path(unquote(parsed.path)).resolve()}"
        if parsed.hostname:
            return f"remote:{parsed.hostname.casefold()}/{normalize_path(parsed.path)}"

    scp = re.fullmatch(r"(?:[^/@:]+@)?(?P<host>[^/:]+):(?P<path>.+)", raw)
    if scp:
        return (
            f"remote:{scp.group('host').casefold()}/"
            f"{normalize_path(scp.group('path').split('?', 1)[0])}"
        )

    if raw.startswith(("/", "./", "../", "~")):
        path = Path(raw).expanduser()
        if not path.is_absolute() and relative_to is not None:
            path = relative_to / path
        return f"path:{path.resolve()}"

    return None


def reference_keys(reference: dict[str, Any], flake: Path) -> set[str]:
    keys: set[str] = set()
    kind = reference.get("type")

    if kind == "github" and reference.get("owner") and reference.get("repo"):
        keys.add(
            "remote:github.com/"
            + normalize_path(f"{reference['owner']}/{reference['repo']}")
        )
    elif kind == "gitlab" and reference.get("owner") and reference.get("repo"):
        host = str(reference.get("host", "gitlab.com")).casefold()
        keys.add(
            f"remote:{host}/"
            + normalize_path(f"{reference['owner']}/{reference['repo']}")
        )
    elif kind == "sourcehut" and reference.get("owner") and reference.get("repo"):
        keys.add(
            "remote:git.sr.ht/"
            + normalize_path(f"{reference['owner']}/{reference['repo']}")
        )

    url = reference.get("url")
    if isinstance(url, str):
        key = remote_key(url, relative_to=flake)
        if key:
            keys.add(key)

    path = reference.get("path")
    if kind == "path" and isinstance(path, str):
        key = remote_key(path, relative_to=flake)
        if key:
            keys.add(key)

    return keys


def reference_url(reference: dict[str, Any]) -> str | None:
    url = reference.get("url")
    if isinstance(url, str):
        return url

    owner = reference.get("owner")
    repo = reference.get("repo")
    if not owner or not repo:
        return None

    kind = reference.get("type")
    if kind == "github":
        return f"https://github.com/{owner}/{repo}.git"
    if kind == "gitlab":
        host = reference.get("host", "gitlab.com")
        return f"https://{host}/{owner}/{repo}.git"
    if kind == "sourcehut":
        return f"https://git.sr.ht/{owner}/{repo}"
    return None


def flake_path(raw: str | None) -> Path:
    value = raw or os.environ.get("NH_FLAKE") or "~/nixos"
    if "#" in value:
        value = value.split("#", 1)[0]
    if "://" in value:
        raise ShipError(f"downstream flake must be a mutable local path, got {value!r}")
    path = Path(value).expanduser().resolve()
    if not (path / "flake.nix").is_file():
        raise ShipError(f"missing downstream flake: {path / 'flake.nix'}")
    if not (path / "flake.lock").is_file():
        raise ShipError(f"missing downstream lock file: {path / 'flake.lock'}")
    return path


def source_root(raw: str) -> Path:
    candidate = Path(raw).expanduser().resolve()
    process = git(candidate, "rev-parse", "--show-toplevel")
    return Path(process.stdout.strip()).resolve()


@dataclass
class Remote:
    name: str
    fetch_urls: list[str]
    push_urls: list[str]
    keys: set[str]

    def as_json(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "fetch_urls": self.fetch_urls,
            "push_urls": self.push_urls,
        }


@dataclass
class DirectInput:
    name: str
    node_name: str
    node: dict[str, Any]
    keys: set[str]

    @property
    def original(self) -> dict[str, Any]:
        value = self.node.get("original", {})
        return value if isinstance(value, dict) else {}

    @property
    def locked(self) -> dict[str, Any]:
        value = self.node.get("locked", {})
        return value if isinstance(value, dict) else {}


def load_lock(flake: Path) -> dict[str, Any]:
    try:
        with (flake / "flake.lock").open(encoding="utf-8") as handle:
            lock = json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        raise ShipError(f"cannot read {flake / 'flake.lock'}: {error}") from error
    if not isinstance(lock.get("nodes"), dict) or not isinstance(lock.get("root"), str):
        raise ShipError(f"invalid lock structure: {flake / 'flake.lock'}")
    return lock


def direct_inputs(lock: dict[str, Any], flake: Path) -> list[DirectInput]:
    nodes = lock["nodes"]
    root_name = lock["root"]
    root = nodes.get(root_name, {})
    root_inputs = root.get("inputs", {}) if isinstance(root, dict) else {}
    if not isinstance(root_inputs, dict):
        raise ShipError("lock root has no direct input map")

    result: list[DirectInput] = []
    for name, node_name in root_inputs.items():
        if not isinstance(node_name, str):
            continue
        node = nodes.get(node_name)
        if not isinstance(node, dict):
            continue
        keys = reference_keys(node.get("original", {}), flake)
        if not keys:
            keys = reference_keys(node.get("locked", {}), flake)
        result.append(DirectInput(name=name, node_name=node_name, node=node, keys=keys))
    return result


def source_remotes(source: Path) -> list[Remote]:
    names = [line for line in git(source, "remote").stdout.splitlines() if line]
    remotes: list[Remote] = []
    for name in names:
        fetch = git(source, "remote", "get-url", "--all", name).stdout.splitlines()
        push_process = git(
            source, "remote", "get-url", "--push", "--all", name, check=False
        )
        push = push_process.stdout.splitlines() if push_process.returncode == 0 else []
        keys = {
            key
            for url in [*fetch, *push]
            if (key := remote_key(url, relative_to=source)) is not None
        }
        remotes.append(Remote(name=name, fetch_urls=fetch, push_urls=push, keys=keys))
    return remotes


def current_branch(source: Path) -> str:
    process = git(source, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    if process.returncode != 0 or not process.stdout.strip():
        raise ShipError(f"source repository is on detached HEAD: {source}")
    return process.stdout.strip()


def upstream_name(source: Path) -> str | None:
    process = git(
        source,
        "rev-parse",
        "--abbrev-ref",
        "--symbolic-full-name",
        "@{upstream}",
        check=False,
    )
    return process.stdout.strip() if process.returncode == 0 else None


def choose_input(
    source: Path, flake: Path, requested: str | None
) -> tuple[DirectInput, list[Remote], str, str, str | None]:
    branch = current_branch(source)
    head = git(source, "rev-parse", "HEAD").stdout.strip()
    upstream = upstream_name(source)
    remotes = source_remotes(source)
    source_keys = (
        set().union(*(remote.keys for remote in remotes)) if remotes else set()
    )
    inputs = direct_inputs(load_lock(flake), flake)

    if requested:
        selected = next((item for item in inputs if item.name == requested), None)
        if selected is None:
            names = ", ".join(item.name for item in inputs)
            raise ShipError(
                f"{requested!r} is not a direct downstream input; available: {names}"
            )
        if not selected.keys.intersection(source_keys):
            raise ShipError(
                f"input {requested!r} does not match any source remote\n"
                f"input identities: {sorted(selected.keys)}\n"
                f"source identities: {sorted(source_keys)}"
            )
    else:
        candidates = [item for item in inputs if item.keys.intersection(source_keys)]
        if len(candidates) > 1:
            branch_matches = [
                item for item in candidates if item.original.get("ref") == branch
            ]
            if len(branch_matches) == 1:
                candidates = branch_matches
        if not candidates:
            raise ShipError(
                "no direct downstream input matches source remotes\n"
                f"source identities: {sorted(source_keys)}"
            )
        if len(candidates) != 1:
            choices = ", ".join(
                f"{item.name}(ref={item.original.get('ref', '<default>')})"
                for item in candidates
            )
            raise ShipError(
                f"multiple direct downstream inputs match source: {choices}; use --input"
            )
        selected = candidates[0]

    matching = [remote for remote in remotes if remote.keys.intersection(selected.keys)]
    if not matching:
        raise ShipError(f"input {selected.name!r} matched no usable source remote")

    preferred_remote = (
        upstream.split("/", 1)[0] if upstream and "/" in upstream else None
    )
    matching.sort(key=lambda remote: remote.name != preferred_remote)
    return selected, matching, branch, head, upstream


def resolve(
    raw_source: str, raw_flake: str | None, requested: str | None
) -> dict[str, Any]:
    source = source_root(raw_source)
    flake = flake_path(raw_flake)
    selected, matching, branch, head, upstream = choose_input(source, flake, requested)
    original = selected.original
    return {
        "source": str(source),
        "branch": branch,
        "head": head,
        "upstream": upstream,
        "flake": str(flake),
        "input": selected.name,
        "input_node": selected.node_name,
        "input_url": reference_url(original) or reference_url(selected.locked),
        "declared_ref": original.get("ref"),
        "pinned_rev": original.get("rev"),
        "locked_rev": selected.locked.get("rev"),
        "matching_remotes": [remote.as_json() for remote in matching],
    }


def require_no_tracked_changes(source: Path) -> None:
    status = git(source, "status", "--porcelain=v1", "--untracked-files=no").stdout
    if status.strip():
        raise ShipError(
            f"source has uncommitted tracked changes after commit phase:\n{status.rstrip()}"
        )


def probe_urls(info: dict[str, Any], selected: DirectInput) -> list[str]:
    urls: list[str] = []
    for remote in info["matching_remotes"]:
        for url in [*remote["fetch_urls"], *remote["push_urls"]]:
            key = remote_key(url)
            if key and key in selected.keys and url not in urls:
                urls.append(url)
    input_url = info.get("input_url")
    if input_url and input_url not in urls:
        urls.append(input_url)
    return urls


def ls_remote(urls: list[str], patterns: list[str]) -> tuple[str, str]:
    errors: list[str] = []
    environment = os.environ.copy()
    environment.setdefault("GIT_TERMINAL_PROMPT", "0")
    for url in urls:
        process = run(
            ["git", "ls-remote", "--symref", url, *patterns],
            env=environment,
            check=False,
        )
        if process.returncode == 0:
            return url, process.stdout
        errors.append(f"{url}: {process.stderr.strip() or 'lookup failed'}")
    raise ShipError("cannot query input remote:\n" + "\n".join(errors))


def verify_published(info: dict[str, Any], selected: DirectInput) -> dict[str, str]:
    head = info["head"]
    pinned = info.get("pinned_rev")
    if pinned:
        raise ShipError(
            f"input {info['input']!r} is pinned to immutable revision {pinned}; "
            "change its flake declaration to a movable ref before shipping"
        )

    urls = probe_urls(info, selected)
    if not urls:
        raise ShipError(f"input {info['input']!r} has no queryable remote URL")

    declared = info.get("declared_ref")
    if declared:
        if declared.startswith("refs/"):
            patterns = [declared]
        else:
            patterns = [
                f"refs/heads/{declared}",
                f"refs/tags/{declared}",
                f"refs/tags/{declared}^{{}}",
            ]
        url, output = ls_remote(urls, patterns)
        entries = [line.split("\t", 1) for line in output.splitlines() if "\t" in line]
        revisions = {sha for sha, _ in entries if not sha.startswith("ref: ")}
        if head not in revisions:
            seen = ", ".join(sorted(revisions)) or "missing"
            raise ShipError(
                f"published input ref {declared!r} does not point to source HEAD\n"
                f"expected: {head}\nremote: {seen}\nurl: {url}"
            )
        published_ref = next((ref for sha, ref in entries if sha == head), declared)
        return {"published_ref": published_ref, "probe_url": url}

    url, output = ls_remote(urls, ["HEAD"])
    default_ref = "HEAD"
    remote_head: str | None = None
    for line in output.splitlines():
        if line.startswith("ref: ") and line.endswith("\tHEAD"):
            default_ref = line.removeprefix("ref: ").split("\t", 1)[0]
        elif line.endswith("\tHEAD"):
            remote_head = line.split("\t", 1)[0]
    if remote_head != head:
        raise ShipError(
            "input remote default branch does not point to source HEAD\n"
            f"expected: {head}\nremote: {remote_head or 'missing'}\n"
            f"ref: {default_ref}\nurl: {url}"
        )
    return {"published_ref": default_ref, "probe_url": url}


def update_input(
    raw_source: str, raw_flake: str | None, requested: str | None
) -> dict[str, Any]:
    info = resolve(raw_source, raw_flake, requested)
    source = Path(info["source"])
    flake = Path(info["flake"])
    require_no_tracked_changes(source)

    inputs_before = direct_inputs(load_lock(flake), flake)
    selected = next(item for item in inputs_before if item.name == info["input"])
    publication = verify_published(info, selected)
    old_rev = selected.locked.get("rev")

    if old_rev != info["head"]:
        run_live(
            ["nix", "flake", "update", selected.name, "--flake", str(flake)],
            cwd=flake,
        )

        inputs_after = direct_inputs(load_lock(flake), flake)
        updated = next(
            (item for item in inputs_after if item.name == selected.name), None
        )
        if updated is None:
            raise ShipError(f"updated input disappeared from lock: {selected.name}")
        new_rev = updated.locked.get("rev")
    else:
        new_rev = old_rev
    if new_rev != info["head"]:
        raise ShipError(
            f"updated lock revision does not equal source HEAD for {selected.name!r}\n"
            f"expected: {info['head']}\nlocked: {new_rev or 'missing'}"
        )

    return {
        **info,
        **publication,
        "old_rev": old_rev,
        "new_rev": new_rev,
        "updated": old_rev != new_rev,
    }


def switch_system(raw_flake: str | None) -> dict[str, Any]:
    flake = flake_path(raw_flake)
    environment = os.environ.copy()
    environment.setdefault("GC_DONT_GC", "1")
    run_live(
        ["nh", "os", "switch", "--no-update-lock-file", str(flake)],
        cwd=flake,
        env=environment,
    )
    return {"flake": str(flake), "switched": True}


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(
        description="Resolve, update, verify, and switch a downstream system flake."
    )
    commands = result.add_subparsers(dest="command", required=True)

    for name in ("resolve", "update", "deploy"):
        command = commands.add_parser(name)
        command.add_argument("--source", default=".", help="source Git worktree")
        command.add_argument("--flake", help="downstream local flake path")
        command.add_argument("--input", help="explicit direct input name")

    switch = commands.add_parser("switch")
    switch.add_argument("--flake", help="downstream local flake path")
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "resolve":
            output = resolve(args.source, args.flake, args.input)
        elif args.command == "update":
            output = update_input(args.source, args.flake, args.input)
        elif args.command == "deploy":
            output = update_input(args.source, args.flake, args.input)
            output.update(switch_system(args.flake))
        else:
            output = switch_system(args.flake)
    except ShipError as error:
        print(f"system-flake: {error}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("system-flake: interrupted", file=sys.stderr)
        return 130

    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
