{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.services.formatNix;
  
  formatScript = pkgs.writeShellScript "format-nix-watcher" ''
    set -e
    WATCH_DIR="${cfg.watchDirectory}"
    cd "$WATCH_DIR"
    
    echo "Starting Nix file watcher on $WATCH_DIR..."
    
    ${pkgs.inotify-tools}/bin/inotifywait -m -r -e modify,create,move \
      --include='.*\.nix$' \
      "$WATCH_DIR" | while read path action file; do
      
      if [[ "$file" =~ \.nix$ ]]; then
        echo "Detected $action on $file, formatting..."
        ${pkgs.alejandra}/bin/alejandra "$path$file"
        echo "✅ Formatted $file"
      fi
    done
  '';
in {
  options.home.services.formatNix = {
    enable = lib.mkEnableOption "automatic Nix file formatting with alejandra";
    watchDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/y0usaf/nixos";
      description = "Directory to watch for Nix file changes";
    };
  };
  
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = [pkgs.alejandra pkgs.inotify-tools];
      
      systemd.services.format-nix-watcher = {
        description = "Watch and format Nix files on change";
        after = ["graphical-session.target"];
        wantedBy = ["default.target"];
        
        serviceConfig = {
          Type = "simple";
          ExecStart = formatScript;
          Restart = "always";
          RestartSec = "5";
        };
      };
    };
  };
}