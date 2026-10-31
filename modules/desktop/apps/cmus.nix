{
  config,
  pkgs,
  ...
}: let
  cmusTsp = "${config.user.homeDirectory}/dev/developing/tern-cmus/cmus-tsp";

  shim = pkgs.writeScript "cmus-tsp-shim" ''
    #!${pkgs.runtimeShell}
    if [ -n "''${CMUS_TSP_CHILD-}" ] || [ "''${TERM_PROGRAM-}" != tern ]; then
      exec ${pkgs.cmus}/bin/cmus "$@"
    fi
    exec ${pkgs.python3}/bin/python3 ${cmusTsp} "$@"
  '';

  cmus = pkgs.symlinkJoin {
    name = "cmus-${pkgs.cmus.version}";
    paths = [pkgs.cmus];
    postBuild = ''
      rm -f $out/bin/cmus
      cp ${shim} $out/bin/cmus
      chmod +x $out/bin/cmus
    '';
  };
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/cmus"
  ];
  environment.systemPackages = [cmus];
  manzil.users."${config.user.name}".files = {
    ".config/cmus/rc".text = ''
      colorscheme palette
      set softvol=true
      set softvol_state=100 100

    '';
    ".config/cmus/palette.theme".text = builtins.readFile ./cmus.theme;
  };
}
