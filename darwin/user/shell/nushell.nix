{
  pkgs,
  config,
  lib,
  ...
}: {
  # Set nushell as default shell
  users.users.y0usaf.shell = pkgs.nushell;

  home-manager.users.y0usaf = {
    home.sessionPath = lib.splitString ":" config.environment.systemPath;
    home.file = {
      ".config/nushell/env.nu" = {
        text = ''
          # Initialize Nix paths for nix-darwin
          let nix_paths = [
            "$HOME/.nix-profile/bin"
            "/etc/profiles/per-user/$env.USER/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
          ]

          let existing_path = if ($env.PATH? | is-empty) {
            []
          } else {
            ($env.PATH | split row ':' | where { |p| $p != "" })
          }
          $env.PATH = ($nix_paths | append $existing_path | uniq | str join ':')

          def export_vars_from_files [dir_path] {
            if not ($dir_path | path exists) {
              return
            }

            let skip_for_opencode = ["ANTHROPIC_API_KEY" "OPENAI_API_KEY"];

            try {
              let files = (ls $dir_path | where type == file);
              for file in $files {
                let var_name = ($file.name | path basename | str replace '.txt' "");

                if not ($var_name =~ '^[a-zA-Z_][a-zA-Z0-9_]*$') {
                  continue
                }

                if ($var_name in $skip_for_opencode) {
                  continue
                }

                try {
                  let content = (open $file.name | str trim);
                  if ($content != "" and not ($content =~ '[[:cntrl:]]') and not ($content =~ '-----')) {
                    load-env { ($var_name): $content }
                  }
                } catch { }
              }
            } catch { }
          }

          export_vars_from_files "/Users/y0usaf/Tokens"

          let hostname = (hostname);
          $env.HOST = $hostname;
          $env.HOSTNAME = $hostname;
        '';
      };

      ".config/nushell/config.nu" = {
        text =
          ''
            # Initialize Nix paths for nix-darwin
            let nix_paths = [
              "$HOME/.nix-profile/bin"
              "/etc/profiles/per-user/$env.USER/bin"
              "/run/current-system/sw/bin"
              "/nix/var/nix/profiles/default/bin"
            ]

            let existing_path = if ($env.PATH? | is-empty) {
              []
            } else {
              ($env.PATH | split row ':' | where { |p| $p != "" })
            }
            $env.PATH = ($nix_paths | append $existing_path | uniq | str join ':')

            def export_vars_from_files [dir_path] {
              if not ($dir_path | path exists) {
                return
              }

              let skip_for_opencode = ["ANTHROPIC_API_KEY" "OPENAI_API_KEY"];

              try {
                let files = (ls $dir_path | where type == file);
                for file in $files {
                  let var_name = ($file.name | path basename | str replace '.txt' "");

                  if not ($var_name =~ '^[a-zA-Z_][a-zA-Z0-9_]*$') {
                    continue
                  }

                  if ($var_name in $skip_for_opencode) {
                    continue
                  }

                  try {
                    let content = (open $file.name | str trim);
                    if ($content != "" and not ($content =~ '[[:cntrl:]]') and not ($content =~ '-----')) {
                      load-env { ($var_name): $content }
                    }
                  } catch { }
                }
              } catch { }
            }

            export_vars_from_files "/Users/y0usaf/Tokens"

            let hostname = (hostname);
            $env.HOST = $hostname;
            $env.HOSTNAME = $hostname;
          ''
          + builtins.readFile ./zellij/zellij.nu
          + ''

            $env.config.history.max_size = 10000
            $env.config.history.file_format = "sqlite"
            $env.config.history.isolation = true

            $env.config.completions.use_ls_colors = true
            $env.config.completions.algorithm = "prefix"

            $env.config.show_banner = false
            uname | reject kernel-version | each { |row|
              let k = ($row | get "kernel-name")
              let kr = ($row | get "kernel-release")
              let os = ($row | get "operating-system")
              let m = ($row | get machine)
              {User: ($env.USER), Host: (hostname), Kernel: $"($k) ($kr)", OS: $os, Machine: $m}
            } | print
          '';
      };

      ".config/nushell/functions.nu" = {
        text = ''
          # Linting
          def lintcheck [] { clear; statix check .; deadnix . }
          def lintfix [] { clear; statix fix .; deadnix . }
        '';
      };

      ".config/nushell/zellij.nu" = {
        text = builtins.readFile ./zellij/zellij.nu;
      };
    };
  };
}
