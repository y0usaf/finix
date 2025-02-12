{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  pythonWrapper = pkgs.writeShellScriptBin "python-wrapped" ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.libGL
      pkgs.glib
    ]}:$LD_LIBRARY_PATH"
    
    exec ${pkgs.python312}/bin/python3 "$@"
  '';
in {
  config = lib.mkIf (builtins.elem "python" profile.features) {
    home.packages = with pkgs; [
      # Python wrapper script
      pythonWrapper
      
      # UV package manager
      uv
      
      # System libraries
      stdenv.cc.cc.lib
      zlib
      libGL
      glib
    ];

    home.sessionVariables = {
      PYTHONUSERBASE = "${config.xdg.dataHome}/python";
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      VIRTUAL_ENV_HOME = "${config.xdg.dataHome}/venvs";
    };
  };
}
