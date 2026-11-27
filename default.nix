{
  pins ? import ./.luin,
  src ? ./.,
}:
let
  inputs = builtins.removeAttrs pins [ "__functor" ];
  outputs = import ./modules/outputs.nix;
  out = outputs (inputs // { inherit self; });
  self = (if builtins.isAttrs src then src else {}) // out // {
    inherit outputs inputs;
    outPath = src.outPath or src;
  };
in
self
