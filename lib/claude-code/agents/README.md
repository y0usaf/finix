# Functional Sub-Agents

Declaratively-defined, function-based sub-agents for Claude Code.

## Philosophy

Agents are **pure functions**, not anthropomorphic roles.

```
❌ "code-reviewer" (a person who reviews)
✓ "compare-configs" (a function that compares)

❌ "debugger" (a person who debugs)
✓ "trace-dependency" (a function that traces)
```

## Available Functions

| Function | Signature | Purpose |
|----------|-----------|---------|
| **search-pattern** | `f(pattern) → matches[]` | Find patterns across codebase |
| **trace-dependency** | `f(identifier) → graph` | Map dependency relationships |
| **compare-configs** | `f(a, b) → diff` | Compute config differences |
| **validate-syntax** | `f(files[]) → report` | Check Nix syntax |
| **resolve-option** | `f(option) → metadata` | Lookup option definitions |
| **graph-imports** | `f(scope) → graph` | Map import relationships |

## Usage

### Explicit Invocation
```bash
# Function call syntax
"Use search-pattern to find 'pkgs.firefox'"
"Use compare-configs for darwin/user/git.nix vs nixos/user/git.nix"
"Use validate-syntax on all modified .nix files"
```

### Automatic Invocation
```bash
# Claude Code decides based on description
"Find all Git configurations and compare Darwin vs NixOS"
→ Auto-invokes: search-pattern, compare-configs
```

### Composition
Functions chain naturally:
```
1. search-pattern("programs.git") → files[]
2. trace-dependency(files[0]) → graph
3. graph-imports(graph.imports) → full_graph
```

## Architecture

### Declarative Definition
Each agent is defined in `lib/claude-code/agents/{name}.nix`:

```nix
{
  name = "function-name";
  description = "What it does. Use when [condition].";
  content = ''
    ---
    name: function-name
    description: What it does. Use when [condition].
    tools: Tool1, Tool2
    model: haiku
    ---

    Function implementation...
  '';
}
```

### Deployment
Agents are deployed via Nix to:
- NixOS: `~/.claude/agents/{name}.md`
- Darwin: `~/.claude/agents/{name}.md`

Configuration managed in:
- `lib/claude-code/agents/default.nix` - Exports all agents
- `lib/claude-code/default.nix` - Includes agents module
- `nixos/user/dev/ai-dev/claude-code/default.nix` - NixOS deployment
- `darwin/user/dev/ai-dev/claude-code/default.nix` - Darwin deployment

## Design Principles

1. **Single Responsibility** - One function per operation
2. **Minimal Tools** - Only necessary capabilities
3. **Pure Functions** - Deterministic, no side effects
4. **Fast Execution** - Use haiku model (cheap, fast)
5. **Clear Contracts** - Explicit input/output types
6. **Composability** - Functions chain naturally

## Benefits

- **Predictability**: Same input → same output
- **Efficiency**: Minimal tool access = faster execution
- **Clarity**: No ambiguity about purpose
- **Reusability**: Pure functions work anywhere
- **Testability**: Clear contracts
- **Maintainability**: Declarative definition in Nix

## Common Workflows

### Pre-Commit Validation
```
validate-syntax → check modified files
```

### Configuration Audit
```
1. search-pattern → find all configs
2. compare-configs → diff Darwin vs NixOS
```

### Debugging
```
1. resolve-option → understand what it does
2. trace-dependency → see where it's used
3. validate-syntax → check for errors
```

### Refactoring
```
1. search-pattern → find all references
2. trace-dependency → map dependencies
3. graph-imports → visualize structure
```

## Adding New Functions

Template:
```nix
{
  name = "verb-noun";
  description = "Does X. Use when Y.";
  content = ''
    ---
    name: verb-noun
    description: Does X. Use when Y.
    tools: Tool1, Tool2
    model: haiku
    ---

    You are a [function] function.

    ## Function Signature
    ```
    f(input) → output
    ```

    ## Behavior
    1. Step 1
    2. Step 2
    ...

    ## Output Format
    ```
    [Structured output]
    ```

    You are a pure function. [Action].
  '';
}
```

After creating:
1. Add to `lib/claude-code/agents/default.nix`
2. Add deployment in both system configs
3. Rebuild: `alejandra . && nh os switch` (NixOS) or `nh darwin switch ~/nixos` (Darwin)

## Anti-Patterns

**Avoid:**
- Anthropomorphization (agents as "workers")
- Decision-making beyond function scope
- General-purpose agents
- Duplicate functionality
- Unnecessary tools

**Instead:**
- Define clear input/output
- Single transformation
- Focused purpose
- Minimal tool set

## Model Selection

- **haiku**: Default (fast, cheap, sufficient for pure functions)
- **sonnet**: Complex logic requiring nuanced analysis
- **opus**: Rarely needed (keep functions simple)
