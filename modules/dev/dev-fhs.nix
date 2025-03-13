#===============================================================================
#                      🏗️ Universal FHS Development Environment 🏗️
#===============================================================================
# 🧰 Provides a standard Linux filesystem hierarchy for development tools
# 🔄 Compatible with Python, Node.js, CUDA, and other development tools
# 🛠️ Allows using UV for Python environment management within FHS
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = {
    # Create the FHS environment for development
    home.packages = [
      (pkgs.buildFHSUserEnv {
        name = "devenv";
        targetPkgs = pkgs:
          with pkgs; [
            # Core development tools
            gcc
            binutils
            gnumake
            cmake
            pkg-config

            # Python ecosystem
            python3
            python312
            uv

            # Node.js ecosystem
            nodejs_20

            # CUDA if enabled in profile
            (lib.optional (builtins.elem "cuda" profile.features) cudaPackages.cudatoolkit)
            (lib.optional (builtins.elem "cuda" profile.features) cudaPackages.cuda_nvcc)

            # System libraries commonly needed
            stdenv.cc.cc.lib
            zlib
            libGL
            glib
            xorg.libX11
            xorg.libXext
            xorg.libXrender

            # SSL certificates
            cacert

            # Additional useful tools
            git
            ripgrep
            fd
          ];

        profile = ''
          # Set up Python paths
          export PYTHONUSERBASE="$HOME/.local/python"
          export PIP_CACHE_DIR="$HOME/.cache/pip"
          export VIRTUAL_ENV_HOME="$HOME/.local/venvs"

          # Set up SSL certificates
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

          # Set up npm paths
          export NPM_CONFIG_PREFIX="$HOME/.local/npm"
          export NPM_CONFIG_CACHE="$HOME/.cache/npm"

          # Set compiler flags
          export CC=gcc
          export CXX=g++

          # Add local bin to PATH
          export PATH="$HOME/.local/bin:$PATH"

          echo "🏗️ Development environment activated!"
        '';

        runScript = "bash";
      })
    ];

    # Add a shell alias for convenience
    programs.zsh.shellAliases = {
      dev = "devenv";
    };

    # Create a script to initialize a UV environment within the FHS env
    home.file.".local/bin/uv-init" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        if [ -z "$1" ]; then
          echo "Usage: uv-init <environment-name>"
          exit 1
        fi

        ENV_NAME="$1"
        ENV_PATH="$HOME/.local/venvs/$ENV_NAME"

        devenv bash -c "uv venv $ENV_PATH && echo 'Created UV environment at $ENV_PATH'"

        echo "#!/usr/bin/env bash" > "$HOME/.local/bin/$ENV_NAME"
        echo "devenv bash -c 'source $ENV_PATH/bin/activate && exec bash'" >> "$HOME/.local/bin/$ENV_NAME"
        chmod +x "$HOME/.local/bin/$ENV_NAME"

        echo "🚀 Created environment '$ENV_NAME'. Run '$ENV_NAME' to activate."
      '';
    };

    # Ensure the local bin directory exists
    home.activation.createLocalBin = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.local/bin
      $DRY_RUN_CMD mkdir -p $HOME/.local/venvs
    '';
  };
}
