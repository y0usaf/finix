{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) defaults shell;
  inherit (shell) zellij;
  flakeDirectory = config.user.paths.flake.path;

  settings = {
    banner = ''
      $env.config.show_banner = false
    '';

    history = ''
      $env.config.history.max_size = 10000
      $env.config.history.file_format = "sqlite"
    '';

    completion = ''
      $env.config.completions.algorithm = "fuzzy"
    '';

    carapace = ''
      source ~/.config/nushell/carapace.nu
    '';
  };

  aliases =
    ''
      def lintcheck [] { clear; ^statix check .; ^deadnix . }
      def lintfix [] { clear; ^statix fix .; ^deadnix . }

      alias wallust = wt
      alias claude = claude --allow-dangerously-skip-permissions
      alias buncodex = bunx --bun @openai/codex
      alias gemini = bunx --bun @google/gemini-cli@preview

      alias la = lsd -A --color=always --group-dirs=first --icon=always
      alias ll = lsd -l --color=always --group-dirs=first --icon=always
      alias lt = lsd -A --tree --color=always --group-dirs=first --icon=always

      def dir [...args: string] { ^dir --color=auto ...$args }
      def grep [...args: string] { ^rg --color auto ...$args }
      def egrep [...args: string] { ^rg --color auto ...$args }
      def fgrep [...args: string] { ^rg -F --color auto ...$args }
      def "l." [] { ^lsd -A | lines | where $it =~ '^\.' }

      def wget [...args: string] { ^wget $"--hsts-file=($env.XDG_DATA_HOME)/wget-hsts" ...$args }
      def svn [...args: string] { ^svn --config-dir $"($env.XDG_CONFIG_HOME)/subversion" ...$args }

      def adb [...args: string] { with-env { HOME: $"($env.XDG_DATA_HOME)/android" } { ^adb ...$args } }
      def mocp [...args: string] { ^mocp -M $"($env.XDG_CONFIG_HOME)/moc" -O $"MOCDir=($env.XDG_CONFIG_HOME)/moc" ...$args }
      def yarn [...args: string] { ^yarn --use-yarnrc $"($env.XDG_CONFIG_HOME)/yarn/config" ...$args }

      def pkgs [query: string] {
        ^nix-store --query --requisites /run/current-system | lines | each { |l| $l | str replace -r '^[^-]*-' "" } | sort | uniq | where $it =~ $query
      }

      def pkgcount [] {
        ^nix-store --query --requisites /run/current-system | lines | each { |l| $l | str replace -r '^[^-]*-' "" } | sort | uniq | length
      }

      def buildtime [] { timeit { ^nix build $"($env.NH_FLAKE)#nixosConfigurations.($env.HOST).config.system.build.toplevel" --option eval-cache false } }
      def hmpush [] { ^git -C ${flakeDirectory} push origin main --force }
      def hmpull [] { ^git -C ${flakeDirectory} fetch origin; ^git -C ${flakeDirectory} reset --hard origin/main }
    ''
    + lib.optionalString config.hardware.nvidia.enable ''
      def nvidia-settings [...args: string] { ^nvidia-settings $"--config=($env.XDG_CONFIG_HOME)/nvidia/settings" ...$args }
      def gpupower [watts: string] { sudo nvidia-smi -pl $watts }
    '';

  exportVars = ''
    def --env export_vars_from_files [dir_path: string] {
      if not ($dir_path | path exists) { return }
      let skip_keys = ["ANTHROPIC_API_KEY", "OPENAI_API_KEY"]
      for file in (ls $dir_path | where type == file | get name) {
        let var_name = ($file | path basename | str replace '.txt' "")
        if not ($var_name =~ '^[a-zA-Z_][a-zA-Z0-9_]*$') { continue }
        if ($var_name in $skip_keys) { continue }
        let content = (open $file | str trim)
        if ($content | is-empty) { continue }
        if ($content =~ '-----') { continue }
        load-env {($var_name): $content}
      }
    }
    export_vars_from_files "${config.user.homeDirectory}/Tokens"
  '';

  tempPkgFunction = ''
    def temppkg [package: string] {
      ^nix-shell -p $package --run $"exec ($env.SHELL)"
    }
  '';

  tempRunFunction = ''
    def temprun [package: string, ...args: string] {
      ^nix run $"nixpkgs#($package)" -- ...$args
    }
  '';

  localFunctions =
    if config.networking.hostName == "y0usaf-laptop"
    then ''
      def fanspeed [percentage: string] {
        ^asusctl fan-curve -m quiet -D $"30c:($percentage),40c:($percentage),50c:($percentage),60c:($percentage),70c:($percentage),80c:($percentage),90c:($percentage),100c:($percentage)" -e true -f gpu
        ^asusctl fan-curve -m quiet -D $"30c:($percentage),40c:($percentage),50c:($percentage),60c:($percentage),70c:($percentage),80c:($percentage),90c:($percentage),100c:($percentage)" -e true -f cpu
      }
    ''
    else "";

  zellijStartup = ''
    # Skip if already in a multiplexer or SSH session
    if ("ZELLIJ" in $env) or ("SSH_CONNECTION" in $env) or ("TMUX" in $env) { return }

    # Skip if in virtual console
    if ($env.TERM? | default "") == "linux" { return }

    # Start Zellij
    if ($env.ZELLIJ_AUTO_ATTACH? | default "false") == "true" {
      exec zellij attach -c
    } else {
      exec zellij
    }
  '';
in {
  options.user.shell.nushell = {
    enable = lib.mkEnableOption "nushell shell configuration";
  };
  config = lib.mkIf shell.nushell.enable {
    environment.systemPackages = [
      pkgs.nushell
      pkgs.carapace
      pkgs.bat
      pkgs.lsd
      pkgs.tree
    ];

    bayt.users."${config.user.name}" = {
      files =
        {
          ".config/nushell/config.nu" = {
            text = lib.concatStringsSep "\n" (
              [
                settings.banner
                settings.history
                settings.completion
                settings.carapace
                aliases
                tempPkgFunction
                tempRunFunction
                localFunctions
              ]
              ++ lib.optional (zellij.enable && zellij.autoStart) "source ~/.config/nushell/zellij.nu"
            );
          };
          ".config/nushell/env.nu" = {
            text =
              exportVars
              + ''

                $env.TERMINAL = "${defaults.terminal}"
                $env.BROWSER = "${defaults.browser}"
                $env.EDITOR = "${defaults.editor}"
              '';
          };
          ".config/nushell/carapace.nu" = {
            source = pkgs.runCommand "carapace-init-nu" {} ''
              export HOME=$(mktemp -d)
              ${pkgs.carapace}/bin/carapace _carapace nushell | ${pkgs.gnused}/bin/sed '/\/build\/.*carapace\/bin/d' > $out
            '';
          };
        }
        // lib.optionalAttrs (zellij.enable && zellij.autoStart) {
          ".config/nushell/zellij.nu" = {
            text = zellijStartup;
          };
        };
    };
  };
}
