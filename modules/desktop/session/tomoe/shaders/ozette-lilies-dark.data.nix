glsl: self: let
  scene = import ./ozette-lilies.data.nix glsl self;
in {
  inherit (scene) fns;
  consts =
    scene.consts
    // scene.paper.dark
    // {
      PAD = 0.3;
    };
}
