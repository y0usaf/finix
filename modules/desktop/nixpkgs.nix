{flakeInputs, ...}: {
  nixpkgs = {
    config.cudaSupport = true;
    overlays = [
      flakeInputs.gpui-shell.overlays.default
      flakeInputs.agent-harness.overlays.default
      # Fix obs-vertical-canvas Qt6GuiPrivate cmake detection
      (_: prev: let
        prevObsPlugins = prev.obs-studio-plugins;
      in {
        obs-studio-plugins =
          prevObsPlugins
          // {
            obs-vertical-canvas = prevObsPlugins.obs-vertical-canvas.overrideAttrs (old: {
              postPatch =
                (old.postPatch or "")
                + ''
                  sed -i '/find_qt(COMPONENTS Widgets COMPONENTS_LINUX Gui)/a find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)' CMakeLists.txt
                '';
            });
          };
      })
    ];
  };
}
