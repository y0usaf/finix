{
  lib,
  pkgs,
  ...
}: let
  version = "v1.9.8";
in {
  options = {
    user.gaming.mods.elden-ring = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = {
        SeamlessCoop = {
          inherit version;
          src = pkgs.fetchzip {
            url = "https://github.com/yuiamoroll/EldenRingSeamlessCoopRelease/releases/download/${version}/Seamless.Co-op.v1.9.8-510-1-9-8-1776128433.zip";
            sha256 = "sha256-GpVqMEoJR4462hCjEjhOCGexkEEN2ewheTsaLEdOX5g=";
            stripRoot = false;
          };
        };
      };
      internal = true;
    };
  };
}
