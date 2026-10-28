{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../tools/git.nix
    ../../tools/tmux.nix
    ./bolo.nix
    ./mado.nix
    ./omarchy.nix
    ./beat-saber.nix
  ];

  options.user.name = lib.mkOption {
    type = lib.types.str;
    default = "steamos";
  };

  config = {
    time.timeZone = "America/Toronto";
    frame.authorizedKeys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGg7LUQDiEec1H1BVCMWBtSwEsCtbdk3K6H63KWR9V+zY15UfNzoEhwPs7UiuyhfwnX6JtxGuAzqjyjHC7Pgooz7v/3szyM5xszxLfsyAZA2mRi3mfeQm2Mh2kKHchFKIOoiztP3w4UOikkz3uuClOw9o8VboqR2tvf2ZRgt/ctw7+TLkVBpY3H+Psq5ili3oVt7bMNGwDAp/NwoB/hsst9YIuBfWrR3E7/MWnN/vG59iuyUINOcy89gVl9VjjjEZP6rYR+YPzMpqi8DWg24mb8qikg8P3Go5Xof3x8mfMUQJmHp7U8yLL8Qt1kcqzCI51RlZdpq/+sce4AtFZ0gtaDLc+yHfCrgM+Oq7I+StmmTv04pdarzfE78u9LB2TIl/frgGIwIn2Ct08gb3FaX/igAp4Mb4BFNAjglcC/yTdaumImHDVqjUp4LfU1YYZ/oexknTDZb3mbShal0vcG8XMANRckhpMQc9KHOy36Z09HYKXwWRvqXeUVrp06M7++4s= claude@y0usaf-desktop"];
    frame.charge.limit = 80;
    frame.storage.poolUuid = "4bac5c02-4a89-4377-8388-ce55ef171552";
    frame.wivrn.enable = true;
    frame.framecorder.enable = true;
    frame.beatSaber.mods = ["SongCore" "BeatSaverDownloader"];
    frame.session.fhsPackages = [pkgs.stremio-linux-shell];
    nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "stremio-linux-shell";

    environment = {
      systemPackages = [pkgs.neovim];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };

    manzil = {
      clobberByDefault = true;
      users.${config.user.name}.files = (import ../shared.nix {inherit lib pkgs;}).bashFiles {};
    };
  };
}
