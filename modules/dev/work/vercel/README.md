# Vercel accounts

The module installs three executable commands, including in noninteractive agent
shells: `vercel`, `vercel-personal`, and `vercel-work`.

Plain `vercel` selects a login in this order:

1. `VERCEL_ACCOUNT=personal` or `VERCEL_ACCOUNT=work`.
2. The GitHub `origin` owner, configured by `personalOwners` and `workOwners`.
   The default recognizes `y0usaf` as personal; no work owner is assumed.

Unknown contexts fail with instructions. `--cwd` participates in routing.
`--scope` and `vercel switch` select a team within that login. They do not change
accounts. The repository's `.vercel/project.json` still selects the project.
Explicit upstream `--global-config` and `--token` flags bypass account routing.

Authenticate each profile once with `vercel-personal login` and
`vercel-work login`. Select the corresponding browser account during each login,
then confirm using `vercel-personal whoami` and `vercel-work whoami`.
Existing default credentials are not copied to either profile.

Credentials live in `$XDG_DATA_HOME/com.vercel.cli/profiles/{personal,work}`,
falling back to `~/.local/share/com.vercel.cli/profiles/{personal,work}`. The default
location is already persisted on the desktop and Framework hosts.

For agents: use plain `vercel` inside a recognized repository. If routing fails,
use repository context to choose `vercel-personal`/`vercel-work`, or ask the user
when ownership is unclear. Use `whoami` to inspect the selected identity. Do not
retry a failed deployment under another account without establishing ownership.
`vercel --help` also explains routing.

The router remains a Python runtime program because account selection depends on
live arguments, working directory, environment and Git remotes. Native Nix renders
its static owner map but cannot perform those runtime decisions. Local routing
test outputs are retired; verify the system build without activation:

```sh
nix build --no-link path:.#nixosConfigurations.y0usaf-desktop.config.system.build.toplevel
```
