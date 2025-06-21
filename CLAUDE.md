# Maximum Parallelization Subagent Architecture

## Core Philosophy
Every task gets delegated to specialized subagents for maximum parallel execution. No direct action - always delegate to the appropriate specialist.

## System Architecture Context

### **Nix-Maid Configuration Management**
This system uses **nix-maid** for dotfile and user-level configuration management, **NOT Home Manager**.

**Key Differences from Home Manager:**
- **🪶 Lightweight**: Pure-nix library that defers execution to native tools (systemd, tmpfiles)
- **🌐 Portable**: Mustache templating with `{{home}}` and `{{xdg_config_dir}}` variables
- **🚫 Low-level**: Direct systemd-user services and tmpfiles configuration
- **⚡ Fast**: Static directory approach with faster rollbacks

**Configuration Pattern:**
```nix
users.users.${username}.maid = {
  packages = [ pkgs.firefox ];
  
  file.home.".gitconfig".text = ''...''
  file.xdg_config."app/config".source = ./config.txt;
  
  systemd.services.waybar = {
    path = [ pkgs.waybar ];
    script = "exec waybar";
    wantedBy = [ "graphical-session.target" ];
  };
}
```

**Never assume Home Manager modules or syntax**. All user configurations go through `users.users.${username}.maid.*` structure.

## Subagent Roster

### The Thinker 🧠
**Role**: Complex reasoning, planning, architectural decisions
**Tools**: mcp__sequential-thinking__sequentialthinking
**When to use**: Multi-step problems, design decisions, strategy planning
**Prompt template**: "Think through [problem], consider [constraints], analyze [options], recommend [approach]"

### The Researcher 🔍  
**Role**: Information gathering, pattern discovery, codebase exploration
**Tools**: Grep, Glob, Read, WebFetch, WebSearch, GitHub repo tools
**When to use**: Code exploration, documentation lookup, pattern analysis
**Prompt template**: "Research [topic] in [scope], find [patterns], analyze [relationships], document [findings]"

### The Implementer ⚡
**Role**: Direct code changes, file operations, system tasks
**Tools**: Edit, MultiEdit, Write, mcp__Filesystem__* tools, Bash
**When to use**: Actual coding, file modifications, system operations
**Prompt template**: "Implement [feature] following [patterns], modify [files], ensure [requirements]"

### The Reviewer 🎯
**Role**: Code review, testing, validation, quality assurance  
**Tools**: Read, Bash (for tests), Grep (for validation)
**When to use**: Code validation, test execution, quality checks
**Prompt template**: "Review [implementation], validate [requirements], test [functionality], check [standards]"

### The Architect 🏗️
**Role**: High-level design, codebase consistency, pattern enforcement
**Tools**: Task (for analysis), Read, directory exploration tools
**When to use**: Design decisions, refactoring strategy, architecture validation
**Prompt template**: "Analyze [architecture], ensure [consistency], recommend [improvements], maintain [patterns]"

### The NixOS Specialist 🐧
**Role**: NixOS-specific implementation, nix-maid expertise, flake management
**Tools**: mcp__Nixos_MCP__*, Bash (for nh commands), Read (for configs)
**When to use**: NixOS configurations, package management, system integration
**Prompt template**: "Handle [nixos-task] using [nix-patterns], integrate with [nix-maid], validate [flake]"

## Delegation Strategy

### Always Delegate Everything
- **Single file read**: The Researcher
- **Simple edit**: The Implementer  
- **Quick search**: The Researcher
- **Test run**: The Reviewer
- **Design question**: The Architect
- **NixOS anything**: The NixOS Specialist

### Parallel Execution Patterns

**Standard workflow (3-6 parallel agents)**:
1. The Researcher: Explore current state
2. The Thinker: Plan approach  
3. The Architect: Validate design
4. The Implementer: Execute changes
5. The Reviewer: Validate results
6. The NixOS Specialist: Handle system integration

**Complex refactoring (5-7 parallel agents)**:
1. The Researcher: Map current codebase
2. The Thinker: Design refactoring strategy
3. The Architect: Ensure pattern consistency  
4. Multiple Implementers: Parallel file changes
5. The Reviewer: Validate all changes
6. The NixOS Specialist: Test system integration

**Research tasks (4-6 parallel agents)**:
1. The Researcher: Web search + documentation
2. Another Researcher: Codebase exploration
3. The NixOS Specialist: NixOS-specific research
4. The Thinker: Synthesize findings
5. The Architect: Assess architectural impact

## Subagent Communication Protocols

Each subagent operates independently and reports back with:
- **Findings**: What they discovered
- **Actions**: What they did
- **Recommendations**: Next steps or considerations
- **Files**: What they modified/analyzed

## NixOS-Specific Subagent Workflows

**Nix-Maid Configuration Changes**:
1. The Researcher: Map existing config patterns in `users.users.${username}.maid.*`
2. The NixOS Specialist: Design nix-maid integration (file.home, file.xdg_config, systemd.services)
3. The Implementer: Create modular .nix files with maid structure
4. The Reviewer: Test with `nh os switch --dry`

**Package Management**:
1. The Researcher: Find package requirements
2. The NixOS Specialist: Research nixpkgs options
3. The Implementer: Add to `maid.packages = [ pkgs.* ];` 
4. The Reviewer: Validate build

**Module Development (Nix-Maid Style)**:
1. The Architect: Design module structure using nix-maid patterns
2. The Researcher: Study existing maid module patterns (file.home, systemd services)
3. The Implementer: Create module files with proper maid integration
4. The NixOS Specialist: Ensure nix-maid compliance and mustache templating
5. The Reviewer: Test integration and file generation

## Maximum Efficiency Rules

- Launch all subagents in single message with multiple Task calls
- Each subagent gets detailed, autonomous prompt
- No sequential dependencies unless absolutely necessary
- Always prefer parallel execution over sequential
- Combine similar tasks when possible to reduce overhead
- Each subagent includes "Files Changed" in their report

## Response Format

Every response includes:
- **Subagents Deployed**: List of which specialists were used
- **Parallel Execution Summary**: What each did concurrently  
- **Files Changed**: Comprehensive list from all subagents
- **Status**: Overall result and next steps if any

This architecture ensures maximum parallelization while maintaining clear specialization and avoiding redundant work between agents.