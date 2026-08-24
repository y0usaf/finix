# Teamfight Tactics (Android) via Waydroid on NVIDIA.
#
# Boots the Waydroid container + session, then launches TFT directly.
# Persistence: /var/lib/waydroid is in the impermanence allowlist
# (hosts/y0usaf-desktop/impermanence.nix), so the image + userdata +
# installed apps survive reboot. The module installs libhoudini once to make
# ARM64-only TFT available in the x86_64 Waydroid container.
{
  config,
  flakeInputs,
  lib,
  pkgs,
  ...
}: let
  # Session start introspects org.freedesktop.Notifications; tomoe answers
  # Introspect with an empty return, which crashes dbus-python
  # ProxyObject._introspect_reply_handler ("missing 1 required positional
  # argument: 'data'") and aborts session start. initializer.py already skips
  # introspection for polkit for the same reason - do the same here.
  waydroidFixed = pkgs.waydroid-nftables.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      substituteInPlace "$out/lib/waydroid/tools/services/notification_manager.py" \
        --replace-fail 'get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")' \
          'get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications", introspect=False)'
      find "$out/lib/waydroid" -name __pycache__ -type d -exec rm -rf {} +
    '';
  });
  runtimePkgs = with pkgs; [
    waydroidFixed
    waydroid-helper
    lxc
    android-tools
    util-linux
  ];
  translatorPkgs = [
    (pkgs.python3.withPackages (p: [p.inquirerpy p.tqdm p.requests]))
  ];
  scripts = ./scripts;
  houdiniScript = pkgs.writeShellScript "tft-houdini-setup" ''
    set -euo pipefail

    WD_SCRIPT_SRC="''${WD_SCRIPT_SRC:?set by module}"
    WD_VERSION="''${WD_ANDROID_VERSION:-13}"
    MARKER=/var/lib/waydroid/.houdini-installed
    MODE="''${1:-install}"

    run_main() {
      (
        # waydroid_script copies overlay files with the caller's umask; a
        # restrictive one yields 0750 overlay dirs that shadow the image and
        # break execv for every non-root Android uid -> fatal reboot ~20s in.
        umask 022
        sudo env "PATH=$PATH" "PYTHONPATH=$WD_SCRIPT_SRC" \
          python3 "$WD_SCRIPT_SRC/main.py" -a "$WD_VERSION" "$@"
      )
    }

    case "$MODE" in
      install)
        if [ ! -f /var/lib/waydroid/waydroid.cfg ]; then
          echo "[houdini] Waydroid is not initialized." >&2
          echo "[houdini] Run tft-launch once to initialize it." >&2
          exit 1
        fi

        if sudo grep -qs 'arm64-v8a' /var/lib/waydroid/waydroid_base.prop 2>/dev/null; then
          sudo touch "$MARKER"
          echo "[houdini] ARM translation already configured."
          exit 0
        fi

        echo "[houdini] installing ARM translation for Android $WD_VERSION..."
        sudo rm -f /var/lib/waydroid/.libndk-installed
        run_main remove libndk || true
        run_main install libhoudini
        sudo touch "$MARKER"
        # heal overlay dirs written earlier under a restrictive umask
        sudo chmod -R a+rX /var/lib/waydroid/overlay
        echo "[houdini] done."
        ;;
      remove)
        echo "[houdini] removing ARM translation..."
        sudo rm -f "$MARKER"
        run_main remove libhoudini
        ;;
      *)
        echo "usage: tft-houdini [install|remove]" >&2
        exit 2
        ;;
    esac
  '';

  # One entry point per script, same shape as the old sandbox flake.
  mkEntry = {
    name,
    withTranslator ? false,
  }:
    pkgs.writeShellApplication {
      name = "tft-${name}";
      runtimeInputs = runtimePkgs ++ lib.optionals withTranslator translatorPkgs;
      text = ''
        export WAYDROID="${waydroidFixed}"
        export LXC="${pkgs.lxc}"
        export ANDROID_TOOLS="${pkgs.android-tools}"
        ${lib.optionalString withTranslator ''
          export WD_SCRIPT_SRC="${flakeInputs.waydroidscript}"
          export TFT_HOUDINI_SCRIPT="${houdiniScript}"
        ''}
        ${
          if name == "houdini"
          then ''exec bash "$TFT_HOUDINI_SCRIPT" "$@"''
          else ''exec bash ${scripts}/${name}.sh "$@"''
        }
      '';
    };
in {
  options.user.gaming.tft = {
    enable = lib.mkEnableOption "Teamfight Tactics via Waydroid";
  };

  config = lib.mkIf config.user.gaming.tft.enable {
    environment.systemPackages = [
      (mkEntry {
        name = "launch";
        withTranslator = true;
      })
      (mkEntry {name = "init";})
      (mkEntry {
        name = "session";
        withTranslator = true;
      })
      (mkEntry {name = "install-tft";})
      (mkEntry {
        name = "houdini";
        withTranslator = true;
      })
      (mkEntry {name = "tune";})
    ];

    # Desktop entry -> tft-launch (on PATH via systemPackages above).
    manzil.users."${config.user.name}".files.".local/share/applications/tft.desktop" = {
      generator = lib.generators.toINI {};
      value."Desktop Entry" = {
        Name = "Teamfight Tactics";
        Comment = "TFT mobile via Waydroid";
        Exec = "tft-launch";
        Terminal = "false";
        Type = "Application";
        Categories = "Game;";
        StartupNotify = "true";
      };
    };
  };
}
