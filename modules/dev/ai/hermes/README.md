# Hermes integration ownership

Finix owns the user-selected policy in `SOUL.md`, `behavior-settings.json`, and
`skills/disabled.json`. Edit those declarations first;
normal activation reconciles only their owned settings and charter blocks.
Runtime sessions, credentials, memories, and other state remain Hermes-owned.

The `hermes-tools` source input owns the runner, reconciliation and offline
command helpers, probes, tests, documentation, skill guides, patches, and package
builders. Its local repository is `~/dev/developing/hermes-tools`. See its
`README.md`, `PROJECT-RUNNER.md`, and `HARDENING.md` for behavior and safety limits.
Do not put substantive tooling implementation back in this module.

This module only selects policy, calls the external builders, and wires packages,
Manzil files, launch settings, and activation. Building does not activate the
system or restart Hermes. Use the normal approved Finix deployment workflow.
