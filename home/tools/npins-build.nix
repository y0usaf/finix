{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools.npins-build;
in {
  options.home.tools.npins-build = {
    enable = lib.mkEnableOption "npins build helpers and shell integration";
  };
  
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      npins
      alejandra
    ];
    
    users.users.y0usaf.maid.file.home.".config/zsh/.zshrc".text = lib.mkAfter ''
      # Npins build helpers
      export NIXOS_CONFIG_PATH="/home/y0usaf/nixos"
      
      # Build system with npins
      nbs() {
        clear
        local dry=""
        local OPTIND
        while getopts "d" opt; do
          case $opt in
            d) dry="--dry-run" ;;
            *) echo "Invalid option: -$OPTARG" >&2 ;;
          esac
        done
        shift $((OPTIND-1))
        
        cd "$NIXOS_CONFIG_PATH"
        echo "Building NixOS configuration with npins..."
        nix-build -E '(import ./default.nix).nixosConfigurations.y0usaf-desktop.config.system.build.toplevel' $dry "$@"
      }
      
      # Switch system (requires sudo)
      nbswitch() {
        clear
        cd "$NIXOS_CONFIG_PATH"
        echo "Building and switching NixOS configuration..."
        local result=$(nix-build -E '(import ./default.nix).nixosConfigurations.y0usaf-desktop.config.system.build.toplevel' --no-out-link)
        if [ $? -eq 0 ]; then
          echo "Switching to new configuration..."
          sudo nixos-rebuild switch --flake . || sudo $result/bin/switch-to-configuration switch
        else
          echo "Build failed!"
          return 1
        fi
      }
      
      # Format nix files
      nbfmt() {
        cd "$NIXOS_CONFIG_PATH"
        echo "Formatting Nix files..."
        alejandra .
      }
      
      # Update npins sources
      nbupdate() {
        cd "$NIXOS_CONFIG_PATH"
        echo "Updating npins sources..."
        npins update
      }
      
      # Combined format and build
      nbfb() {
        nbfmt && nbs "$@"
      }
      
      # Aliases for convenience
      alias nbd="nbs -d"               # dry build
      alias nbf="nbfmt"                # format
      alias nbu="nbupdate"             # update sources
      alias nbfbd="nbfmt && nbs -d"    # format and dry build
      alias nbc="nix-collect-garbage -d"  # clean old generations
    '';
  };
}