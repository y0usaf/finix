_: {
  temppkg = ''
    def temppkg [package: string] {
      ^nix-shell -p $package --run $"exec ($env.SHELL)"
    }
  '';

  temprun = ''
    def temprun [package: string, ...args: string] {
      ^nix run $"nixpkgs#($package)" -- ...$args
    }
  '';
}
