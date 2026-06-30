{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  shojiwmPkg = flakeInputs.shojiwm.packages."${pkgs.stdenv.hostPlatform.system}".default;

  # Re-wrap the upstream binaries with NVIDIA-specific environment variables
  # scoped to the ShojiWM process only (not leaked globally via
  # environment.sessionVariables, which would affect tty2, SDDM, and every
  # other compositor session on the machine).
  #
  # The upstream package.nix wrapper sets GBM_BACKENDS_PATH via --suffix to
  # only the Mesa store path, which does NOT contain nvidia-drm_gbm.so.
  # That library lives in /run/opengl-driver/lib/gbm (libgbm's compiled-in
  # default search path). When GBM_BACKENDS_PATH is set (by the upstream
  # wrapper), libgbm no longer falls back to the compiled default, so
  # GBM_BACKEND=nvidia-drm fails with "failed to open nvidia-drm" unless
  # we prepend the opengl-driver path here.
  #
  # Other compositors (niri, hyprland, sway) set GBM_BACKEND inside their
  # own config files and their binaries do NOT override GBM_BACKENDS_PATH,
  # so libgbm uses /run/opengl-driver/lib/gbm by default. ShojiWM needs
  # this extra wrapper layer because its upstream NixOS package sets
  # GBM_BACKENDS_PATH in its makeWrapper invocation.
  shojiwmWrapped = pkgs.symlinkJoin {
    name = "shojiwm-nvidia-wrapped";
    paths = [shojiwmPkg];
    nativeBuildInputs = [pkgs.makeWrapper];
    passthru = {inherit (shojiwmPkg) providedSessions;};
    postBuild = lib.optionalString config.hardware.nvidia.enable ''
      # shoji_wm — the compositor: needs GBM_BACKEND=nvidia-drm to drive the
      # display through the NVIDIA DRM node, plus the GBM search path fix.
      wrapProgram $out/bin/shoji_wm \
        --prefix GBM_BACKENDS_PATH : /run/opengl-driver/lib/gbm \
        --set-default GBM_BACKEND nvidia-drm \
        --set-default __GLX_VENDOR_LIBRARY_NAME nvidia \
        --set-default __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json \
        --set-default LIBVA_DRIVER_NAME nvidia
      # xdg-desktop-portal-shojiwm — a Wayland client (winit/iced) that also
      # needs to find the NVIDIA GBM backend for EGL on this machine.
      wrapProgram $out/bin/xdg-desktop-portal-shojiwm \
        --prefix GBM_BACKENDS_PATH : /run/opengl-driver/lib/gbm \
        --set-default __GLX_VENDOR_LIBRARY_NAME nvidia \
        --set-default __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
    '';
  };

  # Upstream's package embeds the TypeScript runtime at $out/lib/shojiwm/.
  # (The fork exposed it via passthru.shojiwm-runtime; upstream does not.)
  runtimeDir = "${shojiwmPkg}/lib/shojiwm";
  runtimeConfigSrc = "${runtimeDir}/packages/config";

  # Generate the TSX config from a template with placeholder tokens.
  # The TSX file uses @@TOKEN@@ placeholders which are substituted with
  # Nix config.user.defaults.* values. This avoids all dollar-brace escaping
  # issues between Nix string interpolation and JS template literals.
  tsxContent =
    lib.replaceStrings
    [
      "@@TERMINAL@@"
      "@@LAUNCHER@@"
      "@@FILE_MANAGER@@"
      "@@EDITOR@@"
      "@@IDE@@"
      "@@BROWSER@@"
      "@@DISCORD@@"
      "@@WALLPAPER_PATH@@"
      "@@XWAYLAND_SATELLITE@@"
      "@@FONT_FAMILY@@"
    ]
    [
      config.user.defaults.terminal
      config.user.defaults.launcher
      config.user.defaults.fileManager
      config.user.defaults.editor
      config.user.defaults.ide
      config.user.defaults.browser
      config.user.defaults.discord
      config.user.paths.wallpapers.static.path
      "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
      config.user.ui.fonts.mainFontName
    ]
    (builtins.readFile ./config.tsx);

  # Write the templated TSX to a Nix store path (no shell escaping needed).
  indexTsx = pkgs.writeText "index.tsx" tsxContent;

  # A full-featured ShojiWM configuration using HybridWindowManager for
  # Sway/i3-like tiling (floating is disabled — everything tiles). Key bindings mirror niri:
  #   Alt+T .................. terminal
  #   Super+R ................. launcher
  #   Alt+E ................... file manager
  #   Super+Shift+O ........... terminal editor
  #   Alt+Q ................... close focused window
  #   Alt+F / Super+F ......... toggle maximize
  #   Alt+Shift+F ............. fullscreen (closest: toggle maximize)
  #   Super+Space ............. (disabled — floating is off)
  #   Super+T .................. toggle tabbed/stacking layout
  #   Alt+H/L or Alt+Left/Right  focus tile left/right
  #   Alt+J/K or Alt+Up/Down .... focus tile down/up (closest) / cycle tabs (tabbed mode)
  #   Alt+Shift+H/L etc ....... move tile
  #   Alt+Page_up/Down, Alt+U/I  switch workspace prev/next
  #   Super+1..9 .............. switch to workspace N
  #   Alt+Ctrl+Page_up/Down ... move window to prev/next workspace
  #   Super+Shift+1..9 ........ move window to workspace N
  #   Alt+1..5 ................ spawn IDE/browser/discord/steam/obs
  #   Alt+R / Alt+Shift+R ..... cycle focused column width presets (1/3, 1/2, 2/3 of display)
  #   Alt+G / Alt+Shift+G ..... screenshot region/full
  #   Alt+Shift+C ............. wallpaper shuffle
  #   XF86 media/brightness keys
  #   Super+Shift+Q ........... exit (built-in)
  #   Super+Shift+R ........... reload config (built-in)
  #
  # Spawn-at-startup (onEnable, non-reload):
  #   xwayland-satellite ...... XWayland support (DISPLAY :0)
  #   swaybg .................. random wallpaper from configured path
  shojiwmConfig =
    pkgs.runCommand "shojiwm-config"
    {
      inherit indexTsx;
    }
    ''
      mkdir -p $out/src $out/assets

      # Custom configuration (templated from config.tsx with Nix values)
      cp ${indexTsx} $out/src/index.tsx

      # Copy the window manager module from this repo (customized with
      # tabbed/stacking layout support) and the upstream window animation module.
      cp ${./window-manager.ts} $out/src/window-manager.ts
      cp ${runtimeConfigSrc}/src/window-animation.ts $out/src/window-animation.ts

      # Copy SVG assets for window buttons (close, maximize)
      cp ${runtimeConfigSrc}/assets/*.svg $out/assets/

      cat > $out/package.json <<EOF
      { "name": "shojiwm-config", "private": true, "type": "module" }
      EOF

      # Mirror the tsconfig upstream's dist/install.sh writes for a user
      # config. tsx (esbuild) reads this to pick the JSX runtime; with the
      # full options below it compiles <X/> to the automatic runtime
      # (`import { jsx } from "shoji_wm/jsx-runtime"`) rather than the
      # classic `React.createElement` (which throws "React is not defined"
      # at runtime and wedges the decoration evaluator).
      cat > $out/tsconfig.json <<EOF
      {
        "compilerOptions": {
          "target": "ES2022",
          "module": "ESNext",
          "moduleResolution": "Bundler",
          "jsx": "react-jsx",
          "jsxImportSource": "shoji_wm",
          "strict": true,
          "verbatimModuleSyntax": true,
          "noEmit": true
        }
      }
      EOF

      # node_modules in the store derivation lets the symlinked siblings
      # (window-manager.ts, window-animation.ts) resolve `import "shoji_wm"`
      # from their (symlink-resolved) location here. The real index.tsx
      # deployed in ~/.config/shojiwm resolves it from the separate
      # node_modules/shoji_wm symlink deployed there.
      ln -s ${runtimeDir}/node_modules $out/node_modules
    '';
in {
  config = lib.mkIf config.user.ui.shojiwm.enable {
    # Delegate package installation, Wayland session registration, xdg-desktop-portal
    # setup, and the xdg-desktop-portal-shojiwm systemd service to upstream's
    # official NixOS module (shojiwm.nixosModules.default).
    programs.shojiwm.enable = true;

    # Override the upstream package with the NVIDIA-wrapped version defined
    # above. The upstream NixOS module checks `cfg.package ? override` and
    # calls `.override { xwayland; xwaylandSatellite }` if available;
    # symlinkJoin does not expose .override, so the module installs the
    # (already NVIDIA-wrapped) package as-is. The upstream defaults already
    # bake in xwayland-satellite, so no functionality is lost.
    programs.shojiwm.package = shojiwmWrapped;

    # Extra packages not already installed by programs.shojiwm.
    environment.systemPackages = [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard-rs
      pkgs.jq
      pkgs.swaybg
    ];

    # Deploy the config as a coherent TS project under ~/.config/shojiwm/.
    #
    # The compositor runs the user config through tsx (esbuild). tsx picks the
    # JSX runtime from the tsconfig it discovers by walking up from the config
    # file's directory. The compositor's working_dir is likewise derived by
    # walking up from the config path for the first dir holding tsconfig.json
    # or package.json (install_paths.rs: config_project_dir).
    #
    # manzil deploys `source` entries as symlinks into the nix store by
    # default. A symlinked index.tsx that points out of the config dir tree
    # defeats tsx's tsconfig discovery — esbuild then falls back to the classic
    # JSX runtime (`React.createElement`), which throws `React is not defined`
    # on the first composition eval and wedges the compositor (freeze after
    # spawning a window). So index.tsx, tsconfig.json, and package.json are
    # deployed as real copies (type = "copy"); the rest can be symlinks since
    # `./`-relative imports resolve through them fine. This mirrors upstream
    # dist/install.sh's user-config layout (real tsconfig.json/package.json +
    # a node_modules/shoji_wm symlink).
    manzil.users."${config.user.name}".files = let
      cfg = "${shojiwmConfig}";
    in {
      # Real copies — the project root markers config_project_dir walks up to,
      # and the file whose directory tree tsx's tsconfig discovery anchors on.
      ".config/shojiwm/src/index.tsx" = {
        type = "copy";
        source = "${cfg}/src/index.tsx";
      };
      ".config/shojiwm/tsconfig.json" = {
        type = "copy";
        source = "${cfg}/tsconfig.json";
      };
      ".config/shojiwm/package.json" = {
        type = "copy";
        source = "${cfg}/package.json";
      };

      # Symlinks — contents are read through the link, so resolution is fine.
      ".config/shojiwm/src/window-manager.ts".source = "${cfg}/src/window-manager.ts";
      ".config/shojiwm/src/window-animation.ts".source = "${cfg}/src/window-animation.ts";
      ".config/shojiwm/assets/x.svg".source = "${cfg}/assets/x.svg";
      ".config/shojiwm/assets/maximize-2.svg".source = "${cfg}/assets/maximize-2.svg";
      ".config/shojiwm/assets/minimize-2.svg".source = "${cfg}/assets/minimize-2.svg";

      # Only shoji_wm needs to be resolvable from the config dir (the config
      # and the decoration runtime import from "shoji_wm"). Symlink it to the
      # runtime's workspace package, exactly like upstream install.sh:99.
      ".config/shojiwm/node_modules/shoji_wm".source = "${runtimeDir}/packages/shoji_wm";
    };
  };
}
