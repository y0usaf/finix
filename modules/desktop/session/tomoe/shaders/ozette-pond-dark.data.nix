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
    // scene.paper.dark
    // {
      BODY = 0.14;
      GLINT = rgb ozette.lavender;
      LINES = 0.3;
    };
}
