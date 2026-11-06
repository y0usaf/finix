{
  ozette,
  rgb,
  ...
} @ glsl: self: let
  scene = import ./ozette-pond.data.nix glsl self;
in {
  inherit (scene) fns;
  consts =
    scene.consts
    // scene.paper.light
    // {
      BODY = 0.3;
      GLINT = rgb ozette.white;
      LINES = 0.75;
    };
}
