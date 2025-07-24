_: {
  config = {
    services.udev.extraRules = ''
      KERNEL=="video[0-9]*", GROUP="video", MODE="0660"
    '';
  };
}
