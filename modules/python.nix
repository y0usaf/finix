{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
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
      
      # Just add the C++ library path
      LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH";
    };
  };
}
