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
    ];

    home.sessionVariables = {
      PYTHONUSERBASE = "${config.xdg.dataHome}/python";
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      VIRTUAL_ENV_HOME = "${config.xdg.dataHome}/venvs";
      
      # Use the same libraries defined in your flake.nix
      LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib  # libstdc++
        pkgs.zlib
        pkgs.libGL             # OpenGL libraries for OpenCV
        pkgs.glib             # GLib for system integration
        pkgs.xorg.libX11      # X11 support
        pkgs.xorg.libXext     # X11 extensions
        pkgs.xorg.libXrender  # X11 rendering
      ];
    };
  };
}
