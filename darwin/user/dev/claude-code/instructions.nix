_: {
  home-manager.users.y0usaf = {
    home.file.".claude/CLAUDE.md" = {
      text = ''
        <instructions>
          <thinking>
            ALWAYS think extensively before responding. Use deep analysis, consider edge cases, and reason through problems thoroughly.
            Maximize thinking time. Break problems into smaller steps. Consider alternative approaches. Debug assumptions.
            Use thinking blocks extensively and thoroughly throughout problem-solving, not just at the start. Think at every step.
          </thinking>

          <identity>
            Be critical and reflective. Evidence-based feedback only. No unearned praise.
          </identity>

          <mantras>
            <mantra>Do it right the first time</mantra>
            <mantra>Best code is no code</mantra>
            <mantra>Simple explanations = true understanding</mantra>
          </mantras>

          <tools>
            <tool name="Task">Use for search, analysis, research when needed</tool>
            <tool name="TodoWrite">Use for complex tasks. Mark in_progress before starting, completed immediately after</tool>
          </tools>

          <multi-system>
            Multiple systems running: Darwin (nix-darwin + home-manager) and NixOS.
            Always work from ~/nixos root directory.
            Aim for cohesive configuration across systems. Avoid unnecessary differentiation.
            Only differentiate when required (e.g., Darwin-specific CLI tools, NixOS system packages).
            Different syntaxes (Hjem vs home-manager): aim for configuration similarity, not code sharing—for now.
            Check flake.nix for inputs and shared configuration strategies.
          </multi-system>

          <darwin>
            Uses nix-darwin and home-manager.
            Clone external repos to ~/nixos/tmp/.
            Rebuild workflow: alejandra . && nh darwin switch --dry && nh darwin switch ~/nixos
            Debug and test post-switch before committing.
            Commit after successful switch.
          </darwin>

          <nixos>
            Uses hjem. Clone external repos to tmp/.
            All packages are system-level (environment.systemPackages), not user-level.
            Rebuild: alejandra . && nh os switch --dry && nh os switch
            Commit after successful switch.
          </nixos>

          <hjem-syntax>
            files."path" = { generator = lib.generators.toFormat {}; value = {}; };
          </hjem-syntax>

          <standards>
            Clear naming. Fast failure. Modular design. Security first. Performance aware. Self-documenting code.
          </standards>
        </instructions>
      '';
    };
  };
}
