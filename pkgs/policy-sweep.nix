{pkgs}:
pkgs.stdenv.mkDerivation {
  pname = "policy-sweep";
  version = "1";
  src = ./policy-sweep;
  nativeBuildInputs = [pkgs.makeWrapper];
  doCheck = true;
  checkPhase = ''
    ${pkgs.python3}/bin/python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' $src/sweep.py
  '';
  installPhase = ''
    install -Dm755 $src/sweep.py $out/libexec/sweep.py
    mkdir -p $out/bin $out/share/git-hooks
    makeWrapper ${pkgs.python3}/bin/python3 $out/bin/sweep \
      --add-flags $out/libexec/sweep.py \
      --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ast-grep]}
    printf '#!/bin/sh\nexec %s/bin/sweep hook\n' "$out" > $out/share/git-hooks/pre-commit
    chmod +x $out/share/git-hooks/pre-commit
  '';
}
