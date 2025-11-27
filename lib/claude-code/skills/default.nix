# Skills configuration for Claude Code
# Skills are .md files in .claude/skills/ - Claude sees them in <available_skills>
let
  ensemble = import ./ensemble;
in {
  # Individual skill content exports (for .md file generation)
  ensemble = ensemble.content;
}
