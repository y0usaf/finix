{
  ozette,
  rgb,
  ...
} @ glsl: self: let
  scene = import ./ozette.data.nix glsl self;
in {
  inherit (scene) fns;
  consts =
    scene.consts
    // {
      BASE_BOTTOM = rgb ozette.mist;
      BASE_TOP = rgb ozette.snow;
      DOT = rgb ozette.moss;
      DOTW = 0.07;
      HUE = 0.32;
      PLUM = rgb ozette.frost;
      PLUMW = 0.25;
      RING = 0.006;
    };
}
