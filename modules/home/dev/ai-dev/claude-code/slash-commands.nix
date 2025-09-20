{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.claude.slash-commands;
in {
  options.home.dev.claude.slash-commands = {
    enable = lib.mkEnableOption "Claude slash commands";
  };

  config = lib.mkIf cfg.enable {
    usr = {
      files = {
        # NixOS specific commands
        ".claude/commands/nixos-build.md" = {
          text = ''
            # /nixos-build
            Build and switch NixOS configuration safely:
            1. Format code with `alejandra .`
            2. Test build with `nh os switch --dry`
            3. Apply changes with `nh os switch`
            4. Verify system state
          '';
          clobber = true;
        };

        ".claude/commands/fix-issue.md" = {
          text = ''
            # /fix-issue
            Analyze and fix GitHub issue: $ARGUMENTS
            1. Use `gh issue view` to get issue details
            2. Search codebase for relevant files
            3. Understand the problem context
            4. Implement necessary changes
            5. Test the fix thoroughly
            6. Create PR if requested
          '';
          clobber = true;
        };

        ".claude/commands/review-pr.md" = {
          text = ''
            # /review-pr
            Comprehensive PR review: $ARGUMENTS
            1. Fetch PR details with `gh pr view`
            2. Review changed files for security issues
            3. Check code quality and best practices
            4. Test the changes locally
            5. Provide detailed feedback with suggestions
          '';
          clobber = true;
        };

        ".claude/commands/debug-error.md" = {
          text = ''
            # /debug-error
            Systematic error debugging: $ARGUMENTS
            1. Analyze the error message and stack trace
            2. Identify the failing component
            3. Check logs and system state
            4. Create minimal reproduction case
            5. Apply fix with proper testing
            6. Document the solution
          '';
          clobber = true;
        };

        ".claude/commands/optimize-performance.md" = {
          text = ''
            # /optimize-performance
            Performance optimization workflow: $ARGUMENTS
            1. Profile the current performance
            2. Identify the biggest bottlenecks
            3. Research optimization strategies
            4. Implement improvements incrementally
            5. Benchmark before/after metrics
            6. Monitor for regressions
          '';
          clobber = true;
        };

        ".claude/commands/security-audit.md" = {
          text = ''
            # /security-audit
            Security vulnerability assessment: $ARGUMENTS
            1. Run automated security scanners
            2. Review code for OWASP Top 10 issues
            3. Check dependency vulnerabilities
            4. Audit access controls and authentication
            5. Review data handling and privacy
            6. Create remediation plan with priorities
          '';
          clobber = true;
        };

        ".claude/commands/test-coverage.md" = {
          text = ''
            # /test-coverage
            Improve test coverage: $ARGUMENTS
            1. Run coverage analysis
            2. Identify untested code paths
            3. Write tests for critical functions
            4. Add edge case testing
            5. Verify test quality (not just quantity)
            6. Update CI/CD to enforce coverage thresholds
          '';
          clobber = true;
        };

        ".claude/commands/refactor-code.md" = {
          text = ''
            # /refactor-code
            Safe code refactoring: $ARGUMENTS
            1. Understand current code behavior
            2. Identify refactoring opportunities
            3. Create comprehensive tests first
            4. Apply refactoring in small steps
            5. Run tests after each change
            6. Update documentation if needed
          '';
          clobber = true;
        };
      };
    };
  };
}
