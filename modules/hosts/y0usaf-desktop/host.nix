{pkgs, ...}: {
  user.gaming = {
    proton.enable = true;
    runelite = {
      enable = true;
      scale = 2.0;
    };
  };

  manzil.users.y0usaf.files.".config/linear/linear.toml".source = (pkgs.formats.toml {}).generate "linear-cli-config" {
    workspace = "cook-unity";
  };
}
