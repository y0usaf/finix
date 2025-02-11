{
  lib,
  pkgs,
  config,
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
  };
}
