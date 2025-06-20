{
  inputs,
  shared,
  ...
}: {
  # Install MNW (Modular Neovim Wrapper) as system package
  # This ensures the MNW-wrapped nvim is available system-wide
  environment.systemPackages = [
    inputs.mnw.packages.x86_64-linux.default
  ];
}