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
      BASE_BOTTOM = rgb ozette.abyss;
      BASE_TOP = rgb ozette.dusk;
      DOT = rgb ozette.lime;
      DOTW = 0.08;
      HUE = 0.13;
      PLUM = rgb ozette.plum;
      PLUMW = 0.6;
      RING = 0.004;
    };
}
