{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.user) name homeDirectory tokensDirectory;
in {
  options.user.shell.nushell = {
    enable = lib.mkEnableOption "nushell shell configuration";
  };
  config = lib.mkIf config.user.shell.nushell.enable {
    environment.shells = [pkgs.nushell];
    environment.systemPackages = [
      pkgs.nushell
      pkgs.bat
      pkgs.lsd
      pkgs.tree
    ];

    hjem.users.${name} = {
      files =
        {
          ".config/nushell/aliases.nu" = {
            text = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "alias ${k} = ${v}") (import ./aliases.nix {inherit config;})
            );
            clobber = true;
          };
          ".config/nushell/env.nu" = {
            text = ''
              def export_vars_from_files [dir_path] {
                if not ($dir_path | path exists) {
                  return
                }

                let skip_for_opencode = ["ANTHROPIC_API_KEY" "OPENAI_API_KEY"]

                try {
                  let files = (ls $dir_path | where type == file)
                  for file in $files {
                    let var_name = ($file.name | str replace .txt "")

                    if not ($var_name =~ '^[a-zA-Z_][a-zA-Z0-9_]*$') {
                      continue
                    }

                    if ($var_name in $skip_for_opencode) {
                      continue
                    }

                    try {
                      let content = (open ($dir_path | path join $file.name) | str trim)
                      if ($content != "" and not ($content =~ '[[:cntrl:]]') and not ($content =~ '-----')) {
                        load-env { ($var_name): $content }
                      }
                    } catch { }
                  }
                } catch { }
              }

              export_vars_from_files "${tokensDirectory}"

              let hostname = (sys | get host.name)
              $env.HOST = $hostname
              $env.HOSTNAME = $hostname

              $env.TERMINAL = "${config.user.defaults.terminal}"
              $env.BROWSER = "${config.user.defaults.browser}"
              $env.EDITOR = "${config.user.defaults.editor}"
            '';
            clobber = true;
          };
          ".config/nushell/config.nu" = {
            text = ''
              source aliases.nu
              source functions.nu
              ${lib.optionalString config.user.shell.zellij.enable "source zellij.nu"}

              $env.config.history.max_size = 10000
              $env.config.history.file_format = "sqlite"
              $env.config.history.isolation = true

              $env.config.completions.use_ls_colors = true
              $env.config.completions.algorithm = "prefix"
            '';
            clobber = true;
          };
          ".config/nushell/functions.nu" = {
            text = ''
              # XDG config wrappers
              def adb [...args] { HOME="$XDG_DATA_HOME/android" ^adb ...$args }
              def wget [...args] { ^wget --hsts-file="$XDG_DATA_HOME/wget-hsts" ...$args }
              def nvidia-settings [...args] { ^nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" ...$args }
              def mocp [...args] { ^mocp -M "$XDG_CONFIG_HOME/moc" -O MOCDir="$XDG_CONFIG_HOME/moc" ...$args }
              def yarn [...args] { ^yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config" ...$args }
              def svn [...args] { ^svn --config-dir "$XDG_CONFIG_HOME/subversion" ...$args }

              # Linting
              def lintcheck [] { clear; statix check .; deadnix . }
              def lintfix [] { clear; statix fix .; deadnix . }

              # Package queries
              def pkgs [...args] { nix-store --query --requisites /run/current-system | cut -d- -f2- | lines | sort | uniq | grep -i ...$args }
              def pkgcount [] { nix-store --query --requisites /run/current-system | cut -d- -f2- | lines | sort | uniq | wc -l }

              # Media downloaders - Spotify
              def spotm4a [...args] { ^uvx spotdl --format m4a --output '{title}' ...$args }
              def spotmp3 [...args] { ^uvx spotdl --format mp3 --output '{title}' ...$args }

              # Media downloaders - YouTube
              def ytm4a [...args] { ^yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -x --audio-format m4a --embed-metadata --add-metadata -o '%(title)s.%(ext)s' ...$args }
              def ytmp3 [...args] { ^yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -x --audio-format mp3 --embed-metadata --add-metadata -o '%(title)s.%(ext)s' ...$args }
              def ytmp4 [...args] { ^yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video mp4 --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -vf scale=-2:720' -o '%(title)s.%(ext)s' ...$args }
              def ytmp4s [...args] { ^yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=480]+ba/b[height<=480]' --recode-video mp4 --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libx264 -crf 26 -preset faster -c:a aac -b:a 96k -vf scale=-2:480' -o '%(title)s.%(ext)s' ...$args }
              def ytwebm [...args] { ^yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video webm --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -vf scale=-2:720' -o '%(title)s.%(ext)s' ...$args }
              def ytdiscord [...args] { ^yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video mp4 --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libx264 -crf 28 -preset faster -c:a aac -b:a 96k -vf scale=-2:min(720,ih) -fs 7.8M' -o '%(title)s_discord.%(ext)s' ...$args }

              # Python aliases
              def py [...args] { ^python3 ...$args }
              def pip [...args] { ^pip3 ...$args }
              def venv [...args] { ^python3 -m venv ...$args }

              # Nix utilities
              def buildtime [] {
                time (nix build $"($env.NH_FLAKE)#nixosConfigurations.($env.HOST).config.system.build.toplevel" --option eval-cache false)
              }

              # Utility
              def cat [...args] { bat ...$args }
              def ide [] { zellij --layout ${homeDirectory}/.config/zellij/layouts/ide.kdl }

              # Temporary package management
              def temppkg [package_name] {
                if ($package_name == "") {
                  print "Usage: temppkg package_name"
                  return
                }
                nix-shell -p $package_name --run $"exec ($env.SHELL)"
              }

              def temprun [pkg, ...args] {
                if ($pkg == "") {
                  print "Usage: temprun package_name [args...]"
                  return
                }
                nix run $"nixpkgs#($pkg)" -- ...$args
              }
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs config.user.shell.zellij.enable {
          ".config/nushell/zellij.nu" = {
            text = ''
              if 'ZELLIJ' not-in ($env | columns) {
                if ('TERM' in ($env | columns)) and ($env.TERM != "") {
                  if 'ZELLIJ_AUTO_ATTACH' in ($env | columns) and $env.ZELLIJ_AUTO_ATTACH == 'true' {
                    zellij attach -c
                  } else {
                    zellij
                  }

                  if 'ZELLIJ_AUTO_EXIT' in ($env | columns) and $env.ZELLIJ_AUTO_EXIT == 'true' {
                    exit
                  }
                }
              }
            '';
            clobber = true;
          };
        };
    };
  };
}
