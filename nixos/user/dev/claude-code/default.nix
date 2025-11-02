{
  config,
  lib,
  pkgs,
  claudeCodeLib,
  ...
}: let
  awesome-claude-code = pkgs.fetchFromGitHub {
    owner = "pascalporedda";
    repo = "awesome-claude-code";
    rev = "79fb5bf2cadea245c5a9b6ef318baf0f52574788";
    sha256 = "sha256-1fxRddD7tyq1t4ZNrqArXEG143RBkSv6IpyfcumNRLw=";
  };
in {
  imports = [./claude-code.nix];

  config = lib.mkIf config.user.dev.claude-code.enable {
    usr.files = {
      ".claude/CLAUDE.md" = {
        text = claudeCodeLib.instructions;
        clobber = true;
      };

      ".claude/settings.json" = {
        text = builtins.toJSON claudeCodeLib.settings;
        clobber = true;
      };

      ".claude/commands/nixos-build.md" = {
        text = claudeCodeLib.commands.nixos-build;
        clobber = true;
      };

      ".claude/commands/fix-issue.md" = {
        text = claudeCodeLib.commands.fix-issue;
        clobber = true;
      };

      ".claude/commands/review-pr.md" = {
        text = claudeCodeLib.commands.review-pr;
        clobber = true;
      };

      ".claude/commands/debug-error.md" = {
        text = claudeCodeLib.commands.debug-error;
        clobber = true;
      };

      ".claude/commands/optimize-performance.md" = {
        text = claudeCodeLib.commands.optimize-performance;
        clobber = true;
      };

      ".claude/commands/security-audit.md" = {
        text = claudeCodeLib.commands.security-audit;
        clobber = true;
      };

      ".claude/commands/test-coverage.md" = {
        text = claudeCodeLib.commands.test-coverage;
        clobber = true;
      };

      ".claude/commands/refactor-code.md" = {
        text = claudeCodeLib.commands.refactor-code;
        clobber = true;
      };

      ".claude/skills/ensemble/SKILL.md" = {
        text = claudeCodeLib.skills.ensemble.content;
        clobber = true;
      };

      ".claude/skills/build-status-checker/SKILL.md" = {
        text = claudeCodeLib.skills.build-status-checker.content;
        clobber = true;
      };

      ".claude/skills/linter/SKILL.md" = {
        text = claudeCodeLib.skills.linter.content;
        clobber = true;
      };

      ".claude/skills/test-runner/SKILL.md" = {
        text = claudeCodeLib.skills.test-runner.content;
        clobber = true;
      };

      ".claude/skills/configuration-consistency-auditor/SKILL.md" = {
        text = claudeCodeLib.skills.configuration-consistency-auditor.content;
        clobber = true;
      };

      ".claude/skills/nix-security-scanner/SKILL.md" = {
        text = claudeCodeLib.skills.nix-security-scanner.content;
        clobber = true;
      };

      ".claude/agents/search-pattern.md" = {
        text = claudeCodeLib.agents.search-pattern.content;
        clobber = true;
      };

      ".claude/agents/trace-dependency.md" = {
        text = claudeCodeLib.agents.trace-dependency.content;
        clobber = true;
      };

      ".claude/agents/compare-configs.md" = {
        text = claudeCodeLib.agents.compare-configs.content;
        clobber = true;
      };

      ".claude/agents/validate-syntax.md" = {
        text = claudeCodeLib.agents.validate-syntax.content;
        clobber = true;
      };

      ".claude/agents/resolve-option.md" = {
        text = claudeCodeLib.agents.resolve-option.content;
        clobber = true;
      };

      ".claude/agents/graph-imports.md" = {
        text = claudeCodeLib.agents.graph-imports.content;
        clobber = true;
      };

      ".claude/hooks/notification.ts" = {
        text = claudeCodeLib.hooks.notification;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/stop.ts" = {
        text = claudeCodeLib.hooks.stop;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/subagent_stop.ts" = {
        text = claudeCodeLib.hooks.subagent_stop;
        executable = true;
        clobber = true;
      };

      ".claude/on-agent-need-attention.wav" = {
        source = "${awesome-claude-code}/on-agent-need-attention.wav";
        clobber = true;
      };

      ".claude/on-agent-complete.wav" = {
        source = "${awesome-claude-code}/on-agent-complete.wav";
        clobber = true;
      };
    };
  };
}
