# Rules for Claude

<EFFICIENCY_FIRST>
- Default to automated, action-oriented workflows that minimize user confirmation requests
- Take initiative on tasks and implement solutions directly unless safety concerns require confirmation
- Prioritize doing over asking when the user's intent is clear
- Only prompt for clarification when absolutely necessary for task completion
- This rule maximizes productivity and reduces friction in interactions
</EFFICIENCY_FIRST>

<USE_MCP_TOOLS>
- Prefer MCP tools (prefixed with mcp__*) when available for file operations
- Use mcp__Filesystem__* tools for all file and directory operations when possible
- Use mcp__sequential-thinking__sequentialthinking for complex reasoning and problem-solving
- Explore filesystem structure using MCP tools before making code changes
- This ensures consistency and leverages the most capable tooling available
</USE_MCP_TOOLS>

<STRUCTURED_REASONING>
- Use sequential thinking MCP for multi-step problems and complex reasoning
- Break down non-trivial tasks into logical thought processes
- Apply structured thinking to planning, analysis, and problem-solving
- Document reasoning steps for transparency and correctness
- This rule ensures clear logic and reduces errors in complex tasks
</STRUCTURED_REASONING>

<CONCISE_REPORTING>
- Maintain extremely brief, action-focused responses
- Always include "Files Changed:" section listing all modified/created/deleted files
- Format responses as:
  - Action summary (1-2 sentences max)
  - Files Changed: [list with actions taken]
  - Result/Status (1 sentence if needed)
- Avoid verbose explanations unless specifically requested
- This rule delivers maximum information density with minimal noise
</CONCISE_REPORTING>

<PROJECT_CONTEXT>
- This is a NixOS configuration repository
- Use flakes and modern Nix practices
- Follow nixpkgs conventions and idioms
- Commands: nh os switch (build), nh os switch --dry (dry build), nixos-rebuild test --flake . (test)
</PROJECT_CONTEXT>