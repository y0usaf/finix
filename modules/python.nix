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
    python3Packages.black # Formatter
    python3Packages.pylint # Linter
    python3Packages.pytest # Testing
  ];

  # Add Python-specific environment variables
  home.sessionVariables = {
    PYTHONPATH = "${config.home.homeDirectory}/.local/lib/python3.11/site-packages";
    PIP_REQUIRE_VIRTUALENV = "true"; # Safety feature: require virtualenv for pip install
    # Add UV-specific environment variables for better integration
    UV_PYTHON_DOWNLOADS = "never"; # Prevent UV from managing Python downloads
    UV_PYTHON = "${pkgs.python3}/bin/python3"; # Force UV to use nixpkgs Python interpreter
  };

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

  programs.bash.shellAliases = lib.mkIf (builtins.elem "music" profile.features) {
    spotdl = "source ${config.home.homeDirectory}/.venv/music/bin/activate && ${config.home.homeDirectory}/.venv/music/bin/spotdl download $@ && deactivate";
    spotm4a = "source ${config.home.homeDirectory}/.venv/music/bin/activate && ${config.home.homeDirectory}/.venv/music/bin/spotdl download --format m4a $@ && deactivate";
  };

  programs.zsh.shellAliases = lib.mkIf (builtins.elem "music" profile.features) {
    spotdl = "source ${config.home.homeDirectory}/.venv/music/bin/activate && ${config.home.homeDirectory}/.venv/music/bin/spotdl download $@ && deactivate";
    spotm4a = "source ${config.home.homeDirectory}/.venv/music/bin/activate && ${config.home.homeDirectory}/.venv/music/bin/spotdl download --format m4a $@ && deactivate";
  };
}
