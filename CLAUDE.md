# Claude NixOS Config

## MANDATORY RULES

### File Operations
- ALWAYS use `mcp__Filesystem__*` tools
- NEVER use Read/Write when MCP available

### Task Planning  
- TodoWrite for ALL tasks with 3+ steps
- Mark in_progress BEFORE starting
- Mark completed IMMEDIATELY after finishing
- Only ONE in_progress at a time

### NixOS System
- Uses nix-maid (NOT home-manager)
- Check flake.nix for available inputs
- Clone to `tmp/` folder (in gitignore)

### Build Commands
```bash
alejandra . # format
nh os switch --dry
```