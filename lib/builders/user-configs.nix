{
  pkgs,
  inputs,
}: {
  y0usaf = import ../../configs/users/y0usaf/default.nix {
    inherit pkgs inputs;
  };
  guest = import ../../configs/users/guest/default.nix {
    inherit pkgs inputs;
  };
}
