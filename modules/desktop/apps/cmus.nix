{
  config,
  generators,
  pkgs,
  ...
}: let
  cmusTsp = "${config.user.homeDirectory}/dev/developing/tern-cmus/cmus-tsp";
  python = pkgs.python3.withPackages (ps: [ps.numpy]);

  shim = pkgs.writeScript "cmus-tsp-shim" ''
    #!${pkgs.runtimeShell}
    if [ -n "''${CMUS_TSP_CHILD-}" ] || [ "''${TERM_PROGRAM-}" != tern ]; then
      exec ${pkgs.cmus}/bin/cmus "$@"
    fi
    exec ${python}/bin/python3 ${cmusTsp} "$@"
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
  user.persist.directories = [".config/cmus"];
  environment.systemPackages = [cmus];
  user.files = {
    ".config/cmus/rc".text = ''
      colorscheme palette
      set softvol=true
      set softvol_state=100 100

    '';
    ".config/cmus/palette.theme".text = generators.cmusThemeSource (import ./cmus.data.nix);
  };
}
