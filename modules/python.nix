{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  # Get the exact path to libstdc++
  libPath = "${pkgs.stdenv.cc.cc.lib}/lib";
in {
  config = lib.mkIf (builtins.elem "python" profile.features) {
    home.packages = with pkgs; [
      # Python and UV
      python312
      uv
      
      # Just the essential system libraries
      stdenv.cc.cc.lib  # This provides libstdc++.so.6
    ];

    home.sessionVariables = {
      PYTHONUSERBASE = "${config.xdg.dataHome}/python";
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      VIRTUAL_ENV_HOME = "${config.xdg.dataHome}/venvs";
      
      # Set LD_LIBRARY_PATH more explicitly
      LD_LIBRARY_PATH = lib.concatStringsSep ":" [
        libPath
        (lib.optionalString (builtins.getEnv "LD_LIBRARY_PATH" != "") (builtins.getEnv "LD_LIBRARY_PATH"))
      ];
    };

    # Add a shell hook to ensure the library path is set
    home.shellAliases = {
      "python" = "LD_LIBRARY_PATH=${libPath}:$LD_LIBRARY_PATH python";
    };
  };
}
