_: {
  # Allow passwordless sudo for admin group
  security.sudo.extraConfig = ''
    Defaults env_keep+="HOME"
    %admin ALL=(ALL:ALL) NOPASSWD: ALL
  '';
}
