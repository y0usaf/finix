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
      python3 # Basic Python 3 interpreter
      python312 # Python 3.12 specifically
      uv # Fast Python package installer and resolver

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
      # Add NIX_LD_LIBRARY_PATH for nix-ld
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.libGL
        pkgs.glib
        pkgs.xorg.libX11
        pkgs.xorg.libXext
        pkgs.xorg.libXrender
      ];
      # Set dynamic linker path
      NIX_LD = "${pkgs.stdenv.cc.bintools.dynamicLinker}";
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
