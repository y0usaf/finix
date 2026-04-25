{
  lib,
  pkgs,
  ...
}: let
  version = "0.0.13";
in {
  options = {
    user.gaming.mods.expedition33 = lib.mkOption {
      type = with lib.types; attrsOf raw;
      default = {
        ClairObscurFix = {
          inherit version;
          src = pkgs.fetchzip {
            url = "https://codeberg.org/Lyall/ClairObscurFix/releases/download/${version}/ClairObscurFix_${version}.zip";
            sha256 = "160xv8gb95rn2kpcwv65j3q8fsi1wiayqchgn4gnkrh6g909qzrb";
            stripRoot = false;
          };
        };
      };
      internal = true;
    };
  };
}
