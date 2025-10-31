{claudeCodeLib, ...}: {
  config = {
    home.file = {
      # Instructions (CLAUDE.md)
      ".claude/CLAUDE.md" = {
        text = claudeCodeLib.instructions;
      };

      # Settings (settings.json)
      ".claude/settings.json" = {
        text = builtins.toJSON claudeCodeLib.settings;
      };

      # Statusline script
      ".claude/statusline.sh" = {
        text = claudeCodeLib.statusline;
        executable = true;
      };

      # Slash commands
      ".claude/commands/nixos-build.md" = {
        text = claudeCodeLib.commands.nixos-build;
      };

      ".claude/commands/fix-issue.md" = {
        text = claudeCodeLib.commands.fix-issue;
      };

      ".claude/commands/review-pr.md" = {
        text = claudeCodeLib.commands.review-pr;
      };

      ".claude/commands/debug-error.md" = {
        text = claudeCodeLib.commands.debug-error;
      };

      ".claude/commands/optimize-performance.md" = {
        text = claudeCodeLib.commands.optimize-performance;
      };

      ".claude/commands/security-audit.md" = {
        text = claudeCodeLib.commands.security-audit;
      };

      ".claude/commands/test-coverage.md" = {
        text = claudeCodeLib.commands.test-coverage;
      };

      ".claude/commands/refactor-code.md" = {
        text = claudeCodeLib.commands.refactor-code;
      };

      # Skills
      ".claude/skills/ensemble/SKILL.md" = {
        text = claudeCodeLib.skills.ensemble.content;
      };

      ".claude/skills/build-status-checker/SKILL.md" = {
        text = claudeCodeLib.skills.build-status-checker.content;
      };

      ".claude/skills/linter/SKILL.md" = {
        text = claudeCodeLib.skills.linter.content;
      };

      ".claude/skills/test-runner/SKILL.md" = {
        text = claudeCodeLib.skills.test-runner.content;
      };

      ".claude/skills/configuration-consistency-auditor/SKILL.md" = {
        text = claudeCodeLib.skills.configuration-consistency-auditor.content;
      };

      ".claude/skills/nix-security-scanner/SKILL.md" = {
        text = claudeCodeLib.skills.nix-security-scanner.content;
      };

      # Agents
      ".claude/agents/search-pattern.md" = {
        text = claudeCodeLib.agents.search-pattern.content;
      };

      ".claude/agents/trace-dependency.md" = {
        text = claudeCodeLib.agents.trace-dependency.content;
      };

      ".claude/agents/compare-configs.md" = {
        text = claudeCodeLib.agents.compare-configs.content;
      };

      ".claude/agents/validate-syntax.md" = {
        text = claudeCodeLib.agents.validate-syntax.content;
      };

      ".claude/agents/resolve-option.md" = {
        text = claudeCodeLib.agents.resolve-option.content;
      };

      ".claude/agents/graph-imports.md" = {
        text = claudeCodeLib.agents.graph-imports.content;
      };

      # Hooks
      ".claude/hooks/notification.ts" = {
        text = claudeCodeLib.hooks.notification;
        executable = true;
      };

      ".claude/hooks/stop.ts" = {
        text = claudeCodeLib.hooks.stop;
        executable = true;
      };

      ".claude/hooks/subagent_stop.ts" = {
        text = claudeCodeLib.hooks.subagent_stop;
        executable = true;
      };
    };
  };
}
