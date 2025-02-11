{ lib, pkgs, config, inputs, ... }:

let
  # Set the path to your Python project directory containing pyproject.toml.
  projectDir = ./my-python-project;

  # Use uv2nix to build the Python package.
  pythonPackage = inputs.uv2nix.buildPythonPackage {
    projectDir = projectDir;
    python = pkgs.python3;
    # Optionally, include additional arguments such as buildInputs or overrides.
  };
in {
  # Expose the generated Python package as a system package.
  environment.systemPackages = [ pythonPackage ];
}
