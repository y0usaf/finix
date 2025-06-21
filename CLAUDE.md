# Project Configuration

## Nix-Maid Configuration Management

This system uses **nix-maid** for dotfile and user-level configuration management, **NOT Home Manager**.

**Key Features:**
- Lightweight pure-nix library
- Mustache templating with `{{home}}` and `{{xdg_config_dir}}` variables
- Direct systemd-user services and tmpfiles configuration
- Fast static directory approach

**Configuration Pattern:**
```nix
users.users.${username}.maid = {
  packages = [ pkgs.firefox ];
  
  file.home.".gitconfig".text = ''...'';
  file.xdg_config."app/config".source = ./config.txt;
  
  systemd.services.waybar = {
    path = [ pkgs.waybar ];
    script = "exec waybar";
    wantedBy = [ "graphical-session.target" ];
  };
}
```

**Never assume Home Manager modules or syntax**. All user configurations use `users.users.${username}.maid.*` structure.

## Mandatory Working Principles

### ALWAYS Create Todos
**CRITICAL**: Use TodoWrite for EVERY task, request, or operation regardless of complexity. This includes single-step tasks, simple questions, file reads, searches, or any user interaction. Track ALL progress religiously. ZERO exceptions - TodoWrite is mandatory for ALL circumstances, even trivial ones.

**NEVER** skip TodoWrite for any reason:
- Single file reads require todos
- Simple questions require todos  
- One-line edits require todos
- Any user request requires todos
- All responses require todos

### ALWAYS Use Subagents for ALL Work
**CRITICAL**: Use the Task tool to delegate work to specialized agents for EVERY operation. NEVER perform direct actions yourself - always use subagents regardless of task complexity or simplicity.

**MANDATORY subagent usage for ALL scenarios:**
- Single file reads → delegate to Research agent
- Simple edits → delegate to Implementation agent
- Any search → delegate to Research agent
- Any code change → delegate to Implementation agent
- Any analysis → delegate to Architecture agent
- EVERYTHING must go through subagents

Agent specializations:
- **Research & Analysis**: Codebase exploration, pattern discovery, documentation lookup  
- **Implementation**: Code changes, file operations, system tasks
- **Validation**: Testing, code review, quality assurance
- **Architecture**: Design analysis, consistency checks, pattern validation
- **NixOS Operations**: NixOS configurations, package management, system integration

Deploy multiple agents concurrently whenever possible.

### ALWAYS Use Filesystem MCP for CRUD
**CRITICAL**: Use `mcp__Filesystem__*` tools for ALL file operations:
- `mcp__Filesystem__read_file` instead of Read
- `mcp__Filesystem__write_file` instead of Write  
- `mcp__Filesystem__edit_file` instead of Edit
- `mcp__Filesystem__list_directory` instead of LS
- `mcp__Filesystem__search_files` instead of Grep/Glob

These provide better error handling and work within allowed directories.
