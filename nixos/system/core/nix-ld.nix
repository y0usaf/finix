{pkgs, ...}: {
  config = {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
  };
}
