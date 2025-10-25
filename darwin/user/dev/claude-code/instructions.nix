{...}: {
  home-manager.users.y0usaf = {
    home.file.".claude/CLAUDE.md" = {
      text = ''
        <instructions>
          <thinking>
            ALWAYS think extensively before responding. Use deep analysis, consider edge cases, and reason through problems thoroughly.
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

          <darwin>
            Uses nix-darwin and home-manager. Check flake.nix for inputs.
            Rebuild: alejandra . && nh darwin switch ~/nixos
            Commit after successful switch.
          </darwin>

          <standards>
            Clear naming. Fast failure. Modular design. Security first. Performance aware. Self-documenting code.
          </standards>
        </instructions>
      '';
    };
  };
}
