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

      # System libraries
      stdenv.cc.cc.lib
      zlib
      libGL
      glib
      xorg.libX11
      xorg.libXext
      xorg.libXrender
    ];

    home.sessionVariables = {
      PYTHONUSERBASE = "${config.xdg.dataHome}/python";
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      VIRTUAL_ENV_HOME = "${config.xdg.dataHome}/venvs";
    };

    programs.zsh = {
      envExtra = ''
        # Add library paths for Python
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
          pkgs.libGL
          pkgs.glib
          pkgs.xorg.libX11
          pkgs.xorg.libXext
          pkgs.xorg.libXrender
        ]}:$LD_LIBRARY_PATH"

        # Set dynamic linker path
        export NIX_LD="${pkgs.stdenv.cc.bintools.dynamicLinker}"
      '';
    };
  };
}
