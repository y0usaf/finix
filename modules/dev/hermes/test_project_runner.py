"""Real Git/process integration tests with a deterministic Hermes CLI fixture."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest

SOURCE = Path(__file__).with_name("project_runner.py")
spec = importlib.util.spec_from_file_location("project_runner", SOURCE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

FAKE = r'''
import json, os, pathlib, sys, time
args = sys.argv[1:]
assert "chat" in args and "--oneshot" in args and "--max-turns" in args
assert "--continue" not in args and "-c" not in args and "--resume" not in args
prompt_file = pathlib.Path(args[args.index("--query-file") + 1])
assert pathlib.Path(os.environ["TMPDIR"]) == prompt_file.parent / "scratch"
assert pathlib.Path(os.environ["TMPDIR"]).is_dir()
prompt = prompt_file.read_text()
out = prompt_file.parent / "result.json"
tree = pathlib.Path(args[args.index("--in") + 1])
mode = pathlib.Path(__file__).with_suffix(".mode").read_text()
value = json.loads((tree / "app.json").read_text())["value"]
if "You own the project goal." in prompt:
    if mode == "planneredit":
        (tree / "app.json").write_text('{"value":1}')
    if mode == "malformed":
        out.write_text("not JSON")
        sys.exit(0)
    if value or mode == "premature":
        result = {"decision":"complete", "summary":"Goal achieved", "tasks":[]}
    else:
        task = {"title":"Set value", "instructions":"Set value to 1", "paths":["app.json"], "acceptance":"value equals 1"}
        tasks = [task]
        if mode == "conflict":
            tasks.append({**task, "title":"Set value differently", "instructions":"Set value to 2"})
        if mode == "parallel":
            tasks.append({**task, "title":"Write another file", "paths":["other.json"]})
        result = {"decision":"work", "summary":"Implement goal", "tasks":tasks}
elif "Implement only this task." in prompt:
    if mode == "sleep":
        pathlib.Path(__file__).with_suffix(".pid").write_text(str(os.getpid()))
        time.sleep(60)
    task = json.loads(prompt.split("verification.\n", 1)[1])
    if mode != "empty":
        path = "other.json" if task["title"] == "Write another file" else "app.json"
        number = 2 if task["title"] == "Set value differently" else 1
        (tree / path).write_text(json.dumps({"value":9 if mode == "badcheck" else number}))
    if mode == "scope":
        (tree / "unrelated.txt").write_text("unauthorized change")
    result = {"status":"done", "summary":"Implemented", "tests":["fixture check"], "risks":[]}
else:
    assert "Independently inspect" in prompt
    if mode == "reviewedit":
        (tree / "app.json").write_text('{"value":2}')
    result = {"verdict":"reject" if mode in ("reject", "premature") else "approve", "summary":"Fixture review", "findings":[]}
out.write_text(json.dumps(result))
if mode == "failure":
    sys.exit(1)
'''


class ProjectTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.repo = self.home / "repo"
        self.repo.mkdir()
        mod.git(self.repo, "init", "-b", "main")
        (self.repo / "app.json").write_text('{"value":0}\n')
        mod.git(self.repo, "add", ".")
        mod.git(self.repo, "commit", "-m", "initial")
        self.base = mod.git(self.repo, "rev-parse", "HEAD")
        self.fake = self.home / "hermes-fixture"
        self.fake.write_text("#!" + sys.executable + "\n" + FAKE)
        self.fake.chmod(0o755)
        self.mode("normal")

    def mode(self, name):
        self.fake.with_suffix(".mode").write_text(name)

    def runner(self, **overrides):
        args = dict(repo=str(self.repo), base="HEAD", goal="Set value to 1", workers=2,
                    max_calls=12, max_rounds=3, max_turns=5, agent_seconds=5,
                    max_agent_seconds=60, check_seconds=5, planner_profile="default",
                    worker_profile="worker", reviewer_profile="reviewer", hermes=str(self.fake),
                    state_dir=str(self.home / "runs"),
                    check=[f'''{sys.executable} -c 'import json; assert json.load(open("app.json"))["value"] in (0,1,2)' '''])
        args.update(overrides)
        return mod.Runner(mod.init_run(argparse.Namespace(**args)))

    def assert_original_preserved(self):
        self.assertEqual(mod.git(self.repo, "rev-parse", "HEAD"), self.base)
        self.assertEqual(json.loads((self.repo / "app.json").read_text()), {"value": 0})

    def test_end_to_end_and_idempotent_resume(self):
        (self.repo / "uncommitted.txt").write_text("keep this")
        runner = self.runner()
        runner.run()
        self.assertEqual(runner.state["status"], "complete", runner.state)
        self.assertEqual(runner.state["tasks"][0]["status"], "integrated")
        self.assertEqual(json.loads(mod.git(self.repo, "show", runner.head() + ":app.json")), {"value": 1})
        self.assert_original_preserved()
        self.assertEqual((self.repo / "uncommitted.txt").read_text(), "keep this")
        saved = (runner.root / "state.json").read_bytes()
        mod.Runner(runner.root).run()
        self.assertEqual((runner.root / "state.json").read_bytes(), saved)

    def test_two_workers_integrate_on_latest_branch(self):
        self.mode("parallel")
        runner = self.runner()
        runner.run()
        self.assertEqual(runner.state["status"], "complete", runner.state)
        self.assertEqual([t["status"] for t in runner.state["tasks"]], ["integrated", "integrated"])
        self.assertEqual(json.loads(mod.git(self.repo, "show", runner.head() + ":other.json")), {"value": 1})
        self.assert_original_preserved()

    def test_bad_handoffs_scope_and_empty_work_never_merge(self):
        for mode in ("malformed", "scope", "empty", "reject", "badcheck", "planneredit", "reviewedit", "failure"):
            with self.subTest(mode=mode):
                self.mode(mode)
                runner = self.runner(max_rounds=1)
                runner.run()
                self.assertNotEqual(runner.state["status"], "complete")
                self.assertEqual(runner.head(), self.base)
                self.assert_original_preserved()

    def test_premature_completion_needs_independent_review(self):
        self.mode("premature")
        runner = self.runner(max_rounds=2)
        runner.run()
        self.assertEqual(runner.state["status"], "budget_exhausted")
        self.assertTrue(any("Review rejected" in f for f in runner.state["feedback"]))

    def test_conflicting_workers_do_not_corrupt_branch(self):
        self.mode("conflict")
        runner = self.runner(max_rounds=1)
        runner.run()
        self.assertEqual([t["status"] for t in runner.state["tasks"]], ["integrated", "failed"])
        self.assertEqual(json.loads(mod.git(self.repo, "show", runner.head() + ":app.json")), {"value": 1})
        self.assert_original_preserved()

    def test_call_and_runtime_budgets_persist_on_resume(self):
        for options in ({"max_calls": 1}, {"max_agent_seconds": 5}):
            with self.subTest(options=options):
                runner = self.runner(**options)
                runner.run()
                self.assertEqual(runner.state["status"], "budget_exhausted")
                self.assertEqual(runner.state["calls"], 1)
                resumed = mod.Runner(runner.root)
                resumed.run()
                self.assertEqual(resumed.state["calls"], 1)
                self.assertEqual(resumed.head(), self.base)

    def test_baseline_failure_starts_no_agents(self):
        runner = self.runner(check=[f'{sys.executable} -c "raise SystemExit(1)"'])
        runner.run()
        self.assertEqual(runner.state["status"], "paused")
        self.assertEqual(runner.state["calls"], 0)

    def test_checks_cannot_modify_the_candidate(self):
        runner = self.runner(check=[f'''{sys.executable} -c 'open("untracked", "w").write("oops")' '''])
        runner.run()
        self.assertEqual(runner.state["status"], "paused")
        self.assertEqual(runner.state["calls"], 0)
        self.assertIn("Verification changed", runner.state["last_error"])

    def test_exclusive_lock(self):
        runner = self.runner()
        with runner.lock():
            with self.assertRaisesRegex(mod.RunError, "already has"):
                mod.Runner(runner.root).run()

    def test_journal_recovery_before_and_after_branch_update(self):
        for moved in (False, True):
            with self.subTest(moved=moved):
                runner = self.runner()
                tree = runner.worktree("journal", self.base)
                (tree / "app.json").write_text('{"value":1}')
                mod.git(tree, "add", ".")
                mod.git(tree, "commit", "-m", "candidate")
                candidate = mod.git(tree, "rev-parse", "HEAD")
                runner.state["tasks"] = [{"id":"journal", "status":"ready", "candidate":candidate,
                                          "integration_base":self.base}]
                runner.save()
                if moved:
                    mod.git(self.repo, "update-ref", runner.state["branch"], candidate, self.base)
                recovered = mod.Runner(runner.root)
                recovered.recover()
                self.assertEqual(recovered.head(), candidate)
                self.assertEqual(recovered.state["tasks"][0]["status"], "integrated")
                recovered.recover()
                self.assertEqual(recovered.head(), candidate)

    def test_interrupted_worker_is_preserved_and_replanned(self):
        runner = self.runner()
        runner.state["tasks"] = [{"id":"interrupted", "status":"running", "title":"Old task"}]
        runner.save()
        recovered = mod.Runner(runner.root)
        recovered.run()
        self.assertEqual(recovered.state["status"], "complete", recovered.state)
        self.assertEqual(recovered.state["tasks"][0]["status"], "failed")

    def test_timeout_and_parent_death_stop_worker_process(self):
        self.mode("sleep")
        runner = self.runner(agent_seconds=1, max_rounds=1)
        runner.run()
        pidfile = self.fake.with_suffix(".pid")
        self.assertTrue(pidfile.exists())
        self.assert_stopped(int(pidfile.read_text()))
        pidfile.unlink()
        runner = self.runner(agent_seconds=30, max_agent_seconds=300)
        proc = subprocess.Popen([sys.executable, str(SOURCE), "resume", str(runner.root)],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: proc.poll() is None and proc.kill())
        deadline = time.monotonic() + 10
        while not pidfile.exists() and time.monotonic() < deadline:
            time.sleep(0.02)
        self.assertTrue(pidfile.exists())
        worker_pid = int(pidfile.read_text())
        proc.kill()
        proc.wait(timeout=3)
        self.assert_stopped(worker_pid)
        self.mode("normal")
        recovered = mod.Runner(runner.root)
        recovered.run()
        self.assertEqual(recovered.state["status"], "complete", recovered.state)

    def assert_stopped(self, pid):
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline:
            path = Path(f"/proc/{pid}/stat")
            if not path.exists() or path.read_text().split()[2] == "Z":
                return
            time.sleep(0.02)
        self.fail(f"Worker {pid} is still running")

    def test_planner_path_validation(self):
        for path in (".", "../escape", "/etc", "a/../../etc", ".git/config"):
            with self.subTest(path=path), self.assertRaises(mod.RunError):
                mod.validate_plan({"decision":"work", "summary":"x", "tasks":[
                    {"title":"x", "instructions":"x", "acceptance":"x", "paths":[path]}]}, 2)


if __name__ == "__main__":
    unittest.main()
