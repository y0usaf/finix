glsl: self: let
  scene = import ./ozette-fields.data.nix glsl self;
in {
  inherit (scene) fns;
  consts =
    scene.consts
    // scene.paper.light
    // {
      STRENGTH = 0.55;
    };
}
