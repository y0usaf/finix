glsl: self: let
  scene = import ./ozette-lilies.data.nix glsl self;
in {
  inherit (scene) fns;
  consts =
    scene.consts
    // scene.paper.light
    // {
      PAD = 0.55;
    };
}
