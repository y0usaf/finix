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

      # Add CA certificates
      cacert

      # System libraries
      stdenv.cc.cc.lib
      zlib
      libGL
      glib
      xorg.libX11
      xorg.libXext
      xorg.libXrender

      # Add gcc and binutils for compilation
      gcc
      binutils
    ];

    home.sessionVariables = {
      PYTHONUSERBASE = "${config.xdg.dataHome}/python";
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      VIRTUAL_ENV_HOME = "${config.xdg.dataHome}/venvs";
      # Add SSL certificates path for Python
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
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
      # Add gcc and ld to path
      CC = "${pkgs.gcc}/bin/gcc";
      LD = "${pkgs.binutils}/bin/ld";
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

        # Set SSL certificate paths for Python
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

        # Set dynamic linker path
        export NIX_LD="${pkgs.stdenv.cc.bintools.dynamicLinker}"
      '';
    };
  };
}
