{generators, ...}: {
  security.pki.certificateFiles = [(generators.sourceFile "emudhra-compromised-intermediates.pem" (generators.pemSource (import ./emudhra-compromised-intermediates.data.nix)))];
}
