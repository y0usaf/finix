{
  config,
  lib,
  ...
}: let
  toJSON = lib.generators.toJSON {};
in {
  manzil.users."${config.user.name}".files = {
    ".pi/agent/caveman.json" = {
      generator = toJSON;
      value = {
        defaultLevel = "ultra";
        showStatus = true;
      };
    };

    ".pi/agent/ponytail.json" = {
      generator = toJSON;
      value = {
        defaultMode = "ultra";
      };
    };
  };
}
