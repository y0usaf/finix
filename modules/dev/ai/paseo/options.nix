{lib, ...}: let
  inherit (lib) types;
in {
  options.user.dev.paseo = {
    enable = lib.mkEnableOption "Paseo daemon for coding-agent orchestration";

    listenAddress = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address the daemon binds. 127.0.0.1 plus relay, or a LAN IP.";
    };

    relay = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Use the hosted relay (app.paseo.sh) for remote access. On: phone
          works from anywhere. Off (--no-relay): direct LAN/Tailscale only.
        '';
      };
    };

    environmentFiles = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Files whose contents become environment variables of the daemon (and
        therefore of every agent it spawns). Each file's basename, extension
        stripped and uppercased with non-alphanumerics mapped to _, names the
        variable; the trimmed file content is the value. Keeps API keys out of
        the store (pattern: ~/Tokens/*.txt, one bare key per file).
      '';
    };
  };
}
