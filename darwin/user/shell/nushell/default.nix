{pkgs, ...}: {
  # Set nushell as default shell
  users.users.y0usaf.shell = pkgs.nushell;

  home-manager.users.y0usaf = {
    programs.nushell = {
      enable = true;

      extraEnv = ''
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

      extraConfig = ''
        $env.config.history.max_size = 10000;
        $env.config.history.sync_on_enter = true;
        $env.config.history.file_format = "sqlite";

        $env.config.show_banner = false;
        $env.config.edit_mode = "vi";

        $env.config.completions.case_sensitive = false;
        $env.config.completions.quick = true;
        $env.config.completions.partial = true;
        $env.config.completions.algorithm = "fuzzy";

        $env.config.table.mode = "rounded";
      '';

      shellAliases = {
        # Navigation
        "l." = "ls -a | where name =~ '^\\\.'";
        la = "lsd -A --color=always --group-dirs=first --icon=always";
        ll = "lsd -l --color=always --group-dirs=first --icon=always";
        ls = "lsd -lA --color=always --group-dirs=first --icon=always";
        lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";

        # Search
        grep = "rg --color auto";

        # Development
        lintcheck = "clear; statix check .; deadnix .";
        lintfix = "clear; statix fix .; deadnix .";
        clauded = "claude --dangerously-skip-permissions";

        # System
        pkgs = "nix-store --query --requisites /run/current-system/sw | split row '/' | last | split column '-' | get column2 | sort | uniq | rg -i";
        pkgcount = "nix-store --query --requisites /run/current-system/sw | split row '/' | last | split column '-' | get column2 | sort | uniq | length";

        # Version control
        hmpush = "git -C /Users/y0usaf/nixos push origin main";
        hmpull = "git -C /Users/y0usaf/nixos fetch origin; git -C /Users/y0usaf/nixos reset --hard origin/main";
      };
    };
  };
}
