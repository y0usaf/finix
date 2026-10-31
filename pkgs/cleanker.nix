{pkgs}:
pkgs.stdenv.mkDerivation {
  pname = "cleanker";
  version = "1";
  src = ./cleanker;
  nativeBuildInputs = [pkgs.makeWrapper];
  doCheck = true;
  checkPhase = ''
    ${pkgs.python3}/bin/python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' $src/cleanker.py
  '';
  installPhase = ''
    install -Dm755 $src/cleanker.py $out/libexec/cleanker.py
    mkdir -p $out/bin $out/share/git-hooks
    makeWrapper ${pkgs.python3}/bin/python3 $out/bin/cleanker \
      --add-flags $out/libexec/cleanker.py \
      --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ast-grep]}
    printf '#!/bin/sh\nexec %s/bin/cleanker hook\n' "$out" > $out/share/git-hooks/pre-commit
    chmod +x $out/share/git-hooks/pre-commit
  '';
}
