{pkgs, ...}: {
  config = {
    services.scx = {
      enable = true;
      scheduler = "scx_lavd";
      package = pkgs.scx.rustscheds;
    };
  };
}
