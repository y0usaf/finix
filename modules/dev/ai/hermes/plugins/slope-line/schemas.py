"""The ``line_task`` tool schema — the contract the model reads.

Pure data, no imports: the description is what the model is told about the mechanism and its
limits, so it names the deployment it is for, the harness, the missing capabilities, the waiting
contract, and the report cap. `test_slope_line` checks the numbers here against the constants in
tools.py. The registered name is what the registry actually uses for the definition; the ``name``
key is kept here so the schema reads correctly on its own.
"""

LINE_TASK = {
    "name": "line_task",
    "description": (
        "Delegate one self-contained task to a detached `line` process — a small SBCL agent "
        "harness whose only tool is `shell` (no browser, web, or vision) — and return that run's "
        "own final report. This is the delegation mechanism in this deployment: native subagent "
        "delegation is disabled in config, so this tool is how work is handed to a worker.\n\n"
        "Mechanism: each call starts a separate, detached `line` process with its own trails, then "
        "waits by blocking on the run's trail lock and returns the run's last trail record. The "
        "worker is a separate process with its own context: it never sees this conversation, so "
        "put everything it needs into `goal` and `context`.\n\n"
        "- `background` false (default): waits up to `wait_seconds` for the run to stop. The result "
        "carries status `done` with the report, status `error` with the run's reason, or status "
        "`running`/`timeout` with the exact `line --status <steps>` and `line --log <steps>` "
        "commands to read the run later.\n"
        "- `background` true: returns the run's handle immediately instead of a result — there is "
        "no push delivery for this tool, so the result must be PULLED later from the trail with "
        "the returned check commands, and `kill -INT <pid>` pauses the run.\n\n"
        "A report longer than 262144 characters (256 KiB) is truncated, and the result says so."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "goal": {
                "type": "string",
                "description": (
                    "What the worker must accomplish. Be specific and self-contained — it knows "
                    "nothing about this conversation."
                ),
            },
            "context": {
                "type": "string",
                "description": (
                    "Background the worker needs: file paths, error messages, constraints. Sent "
                    "after the goal, under a literal `Context:` heading."
                ),
            },
            "dir": {
                "type": "string",
                "description": (
                    "Working directory for the worker's shell tool. Default: the current working "
                    "directory."
                ),
            },
            "background": {
                "type": "boolean",
                "default": False,
                "description": (
                    "Start the run and return its handle at once instead of waiting for a result."
                ),
            },
            "wait_seconds": {
                "type": "integer",
                "default": 600,
                "minimum": 1,
                "maximum": 1800,
                "description": (
                    "How long to wait for the run to stop (default 600, max 1800). Ignored when "
                    "`background` is true."
                ),
            },
        },
        "required": ["goal"],
    },
}
