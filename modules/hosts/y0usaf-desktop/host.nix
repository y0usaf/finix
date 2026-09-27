{pkgs, ...}: {
  user.gaming = {
    proton.enable = true;
    runelite.enable = true;
  };

  manzil.users.y0usaf.files.".config/linear/linear.toml".source = (pkgs.formats.toml {}).generate "linear-cli-config" {
    workspace = "cook-unity";
  };
}
