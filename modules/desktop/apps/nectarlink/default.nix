{inputPackages, ...}: {
  user.persist.directories = [
    ".local/share/Nectarlink"
    ".local/share/nectarlink"
  ];
  environment.systemPackages = [
    (inputPackages.nectarlink.nectarlink.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./no-update.patch];
      qtWrapperArgs = (old.qtWrapperArgs or []) ++ ["--unset" "APPIMAGE"];
    }))
  ];
}
