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
    python3Packages.pip
    
    # UV package management tools
    uv
    
    # Development tools
    python3Packages.black    # Formatter
    python3Packages.pylint   # Linter
    python3Packages.pytest   # Testing
  ];

  # Add Python-specific environment variables
  home.sessionVariables = {
    PYTHONPATH = "${config.home.homeDirectory}/.local/lib/python3.11/site-packages";
    PIP_REQUIRE_VIRTUALENV = "true";  # Safety feature: require virtualenv for pip install
    # Add UV-specific environment variables for better integration
    UV_PYTHON_DOWNLOADS = "never";  # Prevent UV from managing Python downloads
    UV_PYTHON = "${pkgs.python3}/bin/python3";  # Force UV to use nixpkgs Python interpreter
  };

  # Create music-related Python virtual environment if music feature is enabled
  home.activation = lib.mkIf (builtins.elem "music" profile.features) {
    createMusicVenv = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "${config.home.homeDirectory}/.venv/music" ]; then
        $DRY_RUN_CMD ${pkgs.uv}/bin/uv venv \
          --python=${pkgs.python3}/bin/python3 \
          "${config.home.homeDirectory}/.venv/music"
        $DRY_RUN_CMD source "${config.home.homeDirectory}/.venv/music/bin/activate"
        $DRY_RUN_CMD ${pkgs.uv}/bin/uv pip install uv spotdl
        $DRY_RUN_CMD deactivate
      fi
    '';
  };
}
