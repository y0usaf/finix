{
  lib,
  pkgs,
  config,
  profile,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    # Python and core tools
    python3
    uv

    # Development tools
    python3Packages.black # Formatter
    python3Packages.pylint # Linter
    python3Packages.pytest # Testing

    # Required system libraries
    stdenv.cc.cc.lib
    zlib
    libGL
    glib
    xorg.libX11
    xorg.libXext
    xorg.libXrender
  ];

  # Add Python-specific environment variables
  home.sessionVariables = {
    # Use UV as the default pip command
    PIP_REQUIRE_VIRTUALENV = "true";
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON = "${pkgs.python3}/bin/python3";
    UV_SYSTEM_PYTHON = "${pkgs.python3}/bin/python3";
    UV_PIP_CONFIGURE = "false";
    
    # Add LD_LIBRARY_PATH for system libraries
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.libGL
      pkgs.glib
      pkgs.xorg.libX11
      pkgs.xorg.libXext
      pkgs.xorg.libXrender
    ];
  };

  # Add UV-specific shell aliases
  programs.zsh = {
    enable = true;
    shellAliases = {
      pip = "${pkgs.uv}/bin/uv pip";
      pip3 = "${pkgs.uv}/bin/uv pip";
      python-venv = "${pkgs.uv}/bin/uv venv";
    };

    initExtra = ''
      # UV initialization
      if command -v uv &> /dev/null; then
        eval "$(uv --generate-shell-completion zsh)"
      fi

      # Remove existing pip from PATH if it exists in ~/.local/bin
      if [[ -f "$HOME/.local/bin/pip" ]]; then
        rm "$HOME/.local/bin/pip"
      fi
    '';
  };

  # Create a script to initialize UV in new shells
  programs.zsh.initExtra = ''
    # UV initialization
    if command -v uv &> /dev/null; then
      eval "$(uv --generate-shell-completion zsh)"
    fi
  '';

  # Create music-related Python virtual environment if music feature is enabled
  home.activation = lib.mkIf (builtins.elem "music" profile.features) {
    createMusicEnv = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "${config.home.homeDirectory}/.venv/music" ]; then
        # Create a new Python environment using UV
        ${pkgs.uv}/bin/uv venv \
          --python=${pkgs.python3}/bin/python3 \
          "${config.home.homeDirectory}/.venv/music"

        # Install required packages
        source "${config.home.homeDirectory}/.venv/music/bin/activate"
        ${pkgs.uv}/bin/uv pip install uv spotdl
        deactivate
      fi
    '';
  };

  programs.zsh.shellAliases = lib.mkIf (builtins.elem "music" profile.features) {
    spotdl = "${config.home.homeDirectory}/.venv/music/bin/spotdl";
    spotm4a = "${config.home.homeDirectory}/.venv/music/bin/spotdl download --format m4a";
  };
}
