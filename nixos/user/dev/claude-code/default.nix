{
  config,
  lib,
  pkgs,
  ...
}: let
  claudeCodeConfig = import ../../../../lib/claude-code;

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
        text = claudeCodeConfig.instructions;
        clobber = true;
      };

      ".claude/settings.json" = {
        text = builtins.toJSON claudeCodeConfig.settings;
        clobber = true;
      };

      ".claude/commands/nixos-build.md" = {
        text = claudeCodeConfig.commands.nixos-build;
        clobber = true;
      };

      ".claude/commands/fix-issue.md" = {
        text = claudeCodeConfig.commands.fix-issue;
        clobber = true;
      };

      ".claude/commands/review-pr.md" = {
        text = claudeCodeConfig.commands.review-pr;
        clobber = true;
      };

      ".claude/commands/debug-error.md" = {
        text = claudeCodeConfig.commands.debug-error;
        clobber = true;
      };

      ".claude/commands/optimize-performance.md" = {
        text = claudeCodeConfig.commands.optimize-performance;
        clobber = true;
      };

      ".claude/commands/security-audit.md" = {
        text = claudeCodeConfig.commands.security-audit;
        clobber = true;
      };

      ".claude/commands/test-coverage.md" = {
        text = claudeCodeConfig.commands.test-coverage;
        clobber = true;
      };

      ".claude/commands/refactor-code.md" = {
        text = claudeCodeConfig.commands.refactor-code;
        clobber = true;
      };

      ".claude/hooks/utils.ts" = {
        text = claudeCodeConfig.hooks.utils;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/notification.ts" = {
        text = claudeCodeConfig.hooks.notification;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/stop.ts" = {
        text = claudeCodeConfig.hooks.stop;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/subagent_stop.ts" = {
        text = claudeCodeConfig.hooks.subagent_stop;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/skill-eval.sh" = {
        text = claudeCodeConfig.hooks.skill_eval;
        executable = true;
        clobber = true;
      };

      # Tool enforcement hooks
      ".claude/hooks/todowrite-reminder.sh" = {
        text = claudeCodeConfig.hooks.todowrite_reminder;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/askuser-reminder.sh" = {
        text = claudeCodeConfig.hooks.askuser_reminder;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/parallel-reminder.sh" = {
        text = claudeCodeConfig.hooks.parallel_reminder;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/tool-tracker.ts" = {
        text = claudeCodeConfig.hooks.tool_tracker;
        executable = true;
        clobber = true;
      };

      ".claude/hooks/tool-validator.ts" = {
        text = claudeCodeConfig.hooks.tool_validator;
        executable = true;
        clobber = true;
      };

      ".claude/on-agent-need-attention.wav" = {
        source = ../../../../lib/claude-code/tuturu.ogg;
        clobber = true;
      };

      ".claude/on-agent-complete.wav" = {
        source = ../../../../lib/claude-code/tuturu.ogg;
        clobber = true;
      };
    };
  };
}
