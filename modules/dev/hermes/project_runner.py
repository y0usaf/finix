#!/usr/bin/env python3
"""Bounded, restartable Hermes project runs. Python standard library only."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import contextlib
import ctypes
import fcntl
import json
import os
from pathlib import Path, PurePosixPath
import shlex
import signal
import subprocess
import sys
import threading
import time
import uuid


class RunError(Exception):
    pass


class BudgetError(RunError):
    pass


def atomic_json(path, value):
    path = Path(path)
    tmp = path.with_suffix(".tmp")
    with tmp.open("w") as out:
        json.dump(value, out, indent=2)
        out.write("\n")
        out.flush()
        os.fsync(out.fileno())
    os.replace(tmp, path)
    fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def git(repo, *args):
    proc = subprocess.run(
        ["git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false",
         "-c", "user.name=Hermes Project", "-c", "user.email=hermes-project@localhost",
         "-C", str(repo), *args], text=True, capture_output=True, timeout=60,
    )
    if proc.returncode:
        raise RunError(f"git {' '.join(args)}: {proc.stderr.strip()}")
    return proc.stdout.rstrip("\n")


def dirty(repo):
    return bool(git(repo, "status", "--porcelain", "--untracked-files=all"))


def text_field(value, key):
    item = value.get(key)
    if not isinstance(item, str) or not item.strip():
        raise RunError(f"Missing nonempty {key}")
    return item


def validate_plan(plan, workers):
    if not isinstance(plan, dict) or plan.get("decision") not in {"work", "complete", "blocked"}:
        raise RunError("Planner must return decision: work, complete, or blocked")
    text_field(plan, "summary")
    tasks = plan.get("tasks", [])
    if not isinstance(tasks, list) or len(tasks) > workers:
        raise RunError(f"Planner may return at most {workers} tasks")
    if bool(tasks) != (plan["decision"] == "work"):
        raise RunError("Only a work decision must contain tasks")
    for task in tasks:
        if not isinstance(task, dict):
            raise RunError("Task must be an object")
        for key in ("title", "instructions", "acceptance"):
            text_field(task, key)
        paths = task.get("paths")
        if not isinstance(paths, list) or not paths:
            raise RunError("Task needs an explicit list of allowed paths")
        for path in paths:
            if not isinstance(path, str) or not path or path.startswith("/"):
                raise RunError("Allowed paths must be relative")
            parts = PurePosixPath(path).parts
            if not parts or any(p in {"..", ".git"} for p in parts) or path == ".":
                raise RunError("Use explicit files or directories, without .. or .git")
    return plan


def in_scope(path, allowed):
    return any(path == p.rstrip("/") or path.startswith(p.rstrip("/") + "/") for p in allowed)


def guarded_exec(parent_pid, command):
    """Linux child supervisor: kill the entire process group if the runner dies.

    Invoked in a new session. The parent-death signal plus parent identity check
    close the spawn race; its child and ordinary tool descendants share the group.
    """
    def terminate(*_):
        os.killpg(os.getpgrp(), signal.SIGKILL)

    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGINT, terminate)
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.prctl(1, signal.SIGTERM, 0, 0, 0) != 0:
        raise OSError(ctypes.get_errno(), "prctl(PR_SET_PDEATHSIG)")
    if os.getppid() != parent_pid:
        terminate()
    result = subprocess.run(command, stdin=subprocess.DEVNULL)
    return result.returncode


class Runner:
    def __init__(self, root):
        self.root = Path(root).resolve()
        self.state = json.loads((self.root / "state.json").read_text())
        if self.state.get("version") != 1:
            raise RunError("Unsupported project state version")
        self.cfg = self.state["config"]
        self.repo = Path(self.cfg["repo"])
        self.mutex = threading.RLock()
        self.processes = set()
        self.cancelled = threading.Event()

    def save(self):
        atomic_json(self.root / "state.json", self.state)

    def event(self, kind, **data):
        with self.mutex:
            with (self.root / "events.jsonl").open("a") as out:
                out.write(json.dumps({"time": time.time(), "event": kind, **data}) + "\n")
                out.flush()
                os.fsync(out.fileno())

    @contextlib.contextmanager
    def lock(self):
        with (self.root / "runner.lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as exc:
                raise RunError("This project already has a running scheduler") from exc
            yield

    def cancel(self, *_):
        self.cancelled.set()
        for proc in list(self.processes):
            self.kill(proc)

    @staticmethod
    def kill(proc):
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

    def execute(self, command, cwd, logfile, seconds, env=None):
        if self.cancelled.is_set():
            raise RunError("Run interrupted")
        with Path(logfile).open("w") as out:
            proc = subprocess.Popen(
                [sys.executable, str(Path(__file__).resolve()), "__exec", str(os.getpid()), *command],
                cwd=cwd, stdout=out, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                start_new_session=True, env=env,
            )
            self.processes.add(proc)
            try:
                if self.cancelled.is_set():
                    self.kill(proc)
                return proc.wait(timeout=seconds)
            except subprocess.TimeoutExpired as exc:
                raise RunError(f"Command timed out after {seconds}s; see {logfile}") from exc
            finally:
                self.kill(proc)
                proc.wait()
                self.processes.discard(proc)

    def head(self):
        return git(self.repo, "rev-parse", self.state["branch"])

    def worktree(self, name, revision):
        path = self.root / "worktrees" / name
        git(self.repo, "worktree", "add", "--detach", str(path), revision)
        return path

    def check(self, tree, name):
        head = git(tree, "rev-parse", "HEAD")
        for i, command in enumerate(self.cfg["checks"]):
            log = self.root / "logs" / f"{name}-check-{i}.log"
            if self.execute(command, tree, log, self.cfg["check_seconds"]):
                raise RunError(f"Verification failed: {shlex.join(command)}; see {log}")
        if dirty(tree) or git(tree, "rev-parse", "HEAD") != head:
            raise RunError("Verification changed repository contents; verification must leave a clean worktree")

    def agent(self, role, tree, instruction):
        with self.mutex:
            if self.state["calls"] >= self.cfg["max_calls"]:
                raise BudgetError("Agent invocation budget exhausted")
            if self.state["reserved_seconds"] + self.cfg["agent_seconds"] > self.cfg["max_agent_seconds"]:
                raise BudgetError("Cumulative agent runtime reservation budget exhausted")
            # Reserve before spawn. Crashes cannot restore spent budget.
            self.state["calls"] += 1
            self.state["reserved_seconds"] += self.cfg["agent_seconds"]
            number = self.state["calls"]
            self.save()
        attempt = self.root / "attempts" / f"{number:04d}-{role}"
        attempt.mkdir()
        scratch = attempt / "scratch"
        scratch.mkdir()
        output = attempt / "result.json"
        prompt = (
            "You are running one bounded task for hermes-project. The scheduler owns orchestration. "
            "Do not delegate, message Bot Chats, create background jobs, publish, push, deploy, "
            "change profiles or memory, or edit scheduler state. Work only in the assigned worktree. "
            "Read and follow the repository's AGENTS.md. Return blockers explicitly. "
            f"Write the required JSON result to {output}. Put any temporary verification scripts "
            f"or scratch files in {scratch} (also TMPDIR), not shared /tmp paths. These are the only "
            "authorized writes outside the worktree. Do not merely describe a next step.\n\n" + instruction
        )
        prompt_path = attempt / "prompt.txt"
        prompt_path.write_text(prompt)
        profile = self.cfg[f"{role}_profile"]
        command = [self.cfg["hermes"]]
        if profile != "default":
            command += ["-p", profile]
        command += ["chat", "--cli", "--in", str(tree), "--oneshot", "-Q",
                    "--max-turns", str(self.cfg["max_turns"]),
                    "--run-budget", str(self.cfg["agent_seconds"]),
                    "--toolsets", "terminal,file", "--query-file", str(prompt_path)]
        self.event("agent_started", role=role, attempt=str(attempt), command=command)
        code = self.execute(command, tree, attempt / "transcript.log", self.cfg["agent_seconds"],
                            env={**os.environ, "TMPDIR": str(scratch)})
        if code:
            raise RunError(f"{role} exited {code}; see {attempt}")
        if not output.is_file() or output.stat().st_size > 128_000:
            raise RunError(f"{role} did not produce a bounded JSON handoff; see {attempt}")
        try:
            result = json.loads(output.read_text())
        except (ValueError, UnicodeError) as exc:
            raise RunError(f"Malformed {role} handoff; see {attempt}") from exc
        if not isinstance(result, dict):
            raise RunError(f"{role} handoff must be an object")
        self.event("agent_finished", role=role, attempt=str(attempt), result=result)
        return result

    def history(self):
        return json.dumps({"goal": self.cfg["goal"], "tasks": self.state["tasks"],
                           "feedback": self.state["feedback"]}, indent=2)

    def plan(self):
        tree = self.worktree(f"planner-{uuid.uuid4().hex[:10]}", self.head())
        base = git(tree, "rev-parse", "HEAD")
        result = self.agent("planner", tree,
            "You own the project goal. Inspect the current repository without modifying it. "
            "Use the durable history below to continue unfinished work. A worker exit is not success. "
            "Choose at most " + str(self.cfg["workers"]) + " bounded, independent tasks for this round. "
            "Avoid overlapping paths. Each task must have explicit allowed repository-relative paths "
            "(files or directory prefixes, no globs), concrete instructions, and acceptance criteria. "
            "Return {\"decision\":\"work|complete|blocked\",\"summary\":\"...\",\"tasks\": "
            "[{\"title\":\"...\",\"instructions\":\"...\",\"paths\":[\"src/file.py\"],"
            "\"acceptance\":\"...\"}]}. Use complete only when the full goal is achieved, "
            "with no tasks. Use blocked only with a concrete blocker and no tasks.\n" + self.history())
        if dirty(tree) or git(tree, "rev-parse", "HEAD") != base:
            raise RunError("Planner modified its repository; plan rejected")
        return validate_plan(result, self.cfg["workers"])

    def worker(self, task):
        try:
            with self.mutex:
                task["status"] = "running"
                task["base"] = self.head()
                task["worktree"] = str(self.root / "worktrees" / task["id"])
                self.save()
            tree = self.worktree(task["id"], task["base"])
            result = self.agent("worker", tree,
                "Implement only this task. You may edit its allowed paths and run relevant tests. "
                "Leave changes uncommitted; the scheduler checks scope and creates the commit. "
                "Do not modify Git history or other worktrees. Return "
                "{\"status\":\"done|blocked\",\"summary\":\"...\",\"tests\":[\"actual test results\"],"
                "\"risks\":[\"...\"]}. Report done only after implementation and verification.\n"
                + json.dumps(task, indent=2))
            text_field(result, "summary")
            if result.get("status") != "done":
                raise RunError("Worker blocked: " + result["summary"])
            if not isinstance(result.get("tests"), list) or not isinstance(result.get("risks"), list):
                raise RunError("Worker must include tests and risks lists")
            if git(tree, "rev-parse", "HEAD") != task["base"]:
                raise RunError("Worker changed Git history")
            git(tree, "add", "-A")
            changed = git(tree, "diff", "--cached", "--name-only", "--no-renames", "-z").split("\0")
            changed = [path for path in changed if path]
            if not changed:
                raise RunError("Worker returned done without a change; planner must assess no-op tasks")
            if any(not in_scope(path, task["paths"]) for path in changed):
                raise RunError("Worker changed paths outside its task: " + repr(changed))
            git(tree, "commit", "-m", f"hermes-project: {task['title']}")
            with self.mutex:
                task.update(status="implemented", commit=git(tree, "rev-parse", "HEAD"), handoff=result)
                self.save()
        except (RunError, OSError, subprocess.SubprocessError) as exc:
            with self.mutex:
                task.update(status="failed", error=str(exc))
                self.save()
                self.event("worker_failed", task=task["id"], error=str(exc))

    def review(self, tree, task=None):
        base = git(tree, "rev-parse", "HEAD")
        target = ("Review the exact candidate diff from " + task["integration_base"] + " to HEAD. "
                  "Check correctness, regressions, scope and the task acceptance criteria.\n" + json.dumps(task)) if task else (
                  "Check whether the entire project goal is actually achieved in this repository. "
                  "Reject missing functionality, unverified claims or remaining required work.\n" + self.history())
        result = self.agent("reviewer", tree,
            "Independently inspect the repository without editing it. " + target +
            "\nReturn {\"verdict\":\"approve|reject\",\"summary\":\"...\",\"findings\":[\"...\"]}.")
        text_field(result, "summary")
        if result.get("verdict") not in {"approve", "reject"} or not isinstance(result.get("findings"), list):
            raise RunError("Invalid review verdict")
        if dirty(tree) or git(tree, "rev-parse", "HEAD") != base:
            raise RunError("Reviewer modified the candidate; rejected")
        if result["verdict"] != "approve":
            raise RunError("Review rejected: " + json.dumps(result))
        return result

    def integrate(self, task):
        try:
            base = self.head()
            tree = self.worktree("candidate-" + task["id"] + "-" + uuid.uuid4().hex[:6], base)
            git(tree, "cherry-pick", task["commit"])
            task["integration_base"] = base
            self.check(tree, task["id"])
            review = self.review(tree, task)
            candidate = git(tree, "rev-parse", "HEAD")
            # Write-ahead journal: reconcile a crash between update-ref and save.
            task.update(status="ready", candidate=candidate, review=review)
            self.save()
            git(self.repo, "update-ref", self.state["branch"], candidate, base)
            task["status"] = "integrated"
            self.save()
            self.event("integrated", task=task["id"], commit=candidate)
        except (RunError, OSError, subprocess.SubprocessError) as exc:
            task.update(status="failed", error=str(exc))
            self.save()

    def recover(self):
        for task in self.state["tasks"]:
            if task["status"] == "running":
                task.update(status="failed", error="Interrupted worker; worktree retained for inspection")
            if task["status"] == "ready":
                head = self.head()
                if head == task["candidate"]:
                    task["status"] = "integrated"
                elif head == task["integration_base"]:
                    git(self.repo, "update-ref", self.state["branch"], task["candidate"], head)
                    task["status"] = "integrated"
                else:
                    raise RunError("Integration branch moved outside its journal; inspect before resuming")
        self.save()

    def run(self):
        with self.lock():
            # A previous scheduler may have exited between construction and lock acquisition.
            self.state = json.loads((self.root / "state.json").read_text())
            if self.state["status"] == "complete":
                return
            self.recover()
            self.state["status"] = "running"
            self.save()
            try:
                if not self.state["baseline_verified"]:
                    tree = self.worktree("baseline-" + uuid.uuid4().hex[:8], self.head())
                    self.check(tree, "baseline")
                    self.state["baseline_verified"] = True
                    self.save()
                while not self.cancelled.is_set():
                    pending = [t for t in self.state["tasks"] if t["status"] == "pending"]
                    if pending:
                        with ThreadPoolExecutor(max_workers=self.cfg["workers"]) as pool:
                            list(pool.map(self.worker, pending))
                    for task in self.state["tasks"]:
                        if self.cancelled.is_set():
                            raise RunError("Run interrupted")
                        if task["status"] == "implemented":
                            self.integrate(task)
                    if self.state["rounds"] >= self.cfg["max_rounds"]:
                        raise BudgetError("Planning round budget exhausted")
                    self.state["rounds"] += 1
                    self.save()
                    plan = self.plan()
                    self.state["feedback"].append(plan["summary"])
                    if plan["decision"] == "blocked":
                        self.state["status"] = "blocked"
                        break
                    if plan["decision"] == "complete":
                        tree = self.worktree("final-" + uuid.uuid4().hex[:8], self.head())
                        try:
                            self.check(tree, "final")
                            self.state["final_review"] = self.review(tree)
                        except BudgetError:
                            raise
                        except RunError as exc:
                            self.state["feedback"].append(str(exc))
                            self.save()
                            continue
                        self.state["status"] = "complete"
                        self.state["result_commit"] = self.head()
                        break
                    for contract in plan["tasks"]:
                        self.state["tasks"].append({**contract, "id": uuid.uuid4().hex[:12], "status": "pending"})
                    self.save()
                if self.cancelled.is_set():
                    self.state["status"] = "paused"
            except BudgetError as exc:
                self.state.update(status="budget_exhausted", last_error=str(exc))
            except (RunError, OSError, subprocess.SubprocessError) as exc:
                self.state.update(status="paused", last_error=str(exc))
            finally:
                self.cancel()
                self.save()
                self.event("run_stopped", status=self.state["status"])


def init_run(args):
    repo = Path(git(Path(args.repo).resolve(), "rev-parse", "--show-toplevel"))
    base = git(repo, "rev-parse", "--verify", "--end-of-options", args.base + "^{commit}")
    ident = uuid.uuid4().hex[:12]
    root = Path(args.state_dir).expanduser().resolve() / ident
    if root.is_relative_to(repo):
        raise RunError("Run state/worktrees must live outside the target repository")
    root.mkdir(parents=True, mode=0o700)
    for directory in ("attempts", "logs", "worktrees"):
        (root / directory).mkdir()
    checks = [shlex.split(command) for command in args.check]
    if any(not command for command in checks):
        raise RunError("Verification commands cannot be empty")
    branch = f"refs/heads/hermes-project/{ident}"
    git(repo, "update-ref", branch, base, "0" * len(base))
    cfg = {key: getattr(args, key) for key in (
        "goal", "workers", "max_calls", "max_rounds", "max_turns", "agent_seconds",
        "max_agent_seconds", "check_seconds", "planner_profile", "worker_profile", "reviewer_profile", "hermes")}
    cfg.update(repo=str(repo), checks=checks)
    atomic_json(root / "state.json", {
        "version": 1, "id": ident, "config": cfg, "base": base, "branch": branch,
        "status": "pending", "baseline_verified": False, "calls": 0, "rounds": 0,
        "reserved_seconds": 0, "tasks": [], "feedback": [],
    })
    return root


def positive(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be positive")
    return number


def main(argv=None):
    parser = argparse.ArgumentParser(prog="hermes-project", description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    start = subs.add_parser("start", help="Create and run a project on a private integration branch")
    start.add_argument("--repo", required=True)
    goal = start.add_mutually_exclusive_group(required=True)
    goal.add_argument("--goal")
    goal.add_argument("--goal-file", type=Path)
    start.add_argument("--base", default="HEAD", help="Committed starting revision (uncommitted edits are excluded)")
    start.add_argument("--check", action="append", required=True, help="Required verification command; shell-split argv, repeatable")
    start.add_argument("--state-dir", default="~/.hermes/project-runs")
    start.add_argument("--hermes", default=os.environ.get("HERMES_PROJECT_HERMES", "hermes"))
    start.add_argument("--planner-profile", default="default")
    start.add_argument("--worker-profile", default="worker")
    start.add_argument("--reviewer-profile", default="reviewer")
    start.add_argument("--workers", type=int, choices=(1, 2), default=2)
    for name, default in (("max-calls", 16), ("max-rounds", 4), ("max-turns", 40),
                          ("agent-seconds", 600), ("max-agent-seconds", 9600), ("check-seconds", 300)):
        start.add_argument("--" + name, type=positive, default=default)
    start.add_argument("--prepare-only", action="store_true", help="Create state without starting agents")
    for command in ("resume", "status"):
        sub = subs.add_parser(command)
        sub.add_argument("run", type=Path, help="Run directory printed by start")
    args = parser.parse_args(argv)
    try:
        if args.command == "start":
            if args.goal_file:
                args.goal = args.goal_file.read_text()
            if not args.goal.strip():
                raise RunError("Goal cannot be empty")
            root = init_run(args)
            print(f"Run: {root}", flush=True)
            if args.prepare_only:
                return 0
        else:
            root = args.run
        runner = Runner(root)
        if args.command == "status":
            print(json.dumps(runner.state, indent=2))
            return 0
        signal.signal(signal.SIGINT, runner.cancel)
        signal.signal(signal.SIGTERM, runner.cancel)
        runner.run()
        print(json.dumps({key: runner.state.get(key) for key in (
            "status", "branch", "result_commit", "calls", "rounds", "last_error")}, indent=2))
        return 0 if runner.state["status"] == "complete" else 2
    except (RunError, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"hermes-project: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "__exec":
        sys.exit(guarded_exec(int(sys.argv[2]), sys.argv[3:]))
    sys.exit(main())
