{
  ensemble = import ./ensemble.nix;
  build-status-checker = import ./build-status-checker.nix;
  linter = import ./linter.nix;
  test-runner = import ./test-runner.nix;
  configuration-consistency-auditor = import ./configuration-consistency-auditor.nix;
  nix-security-scanner = import ./nix-security-scanner.nix;
}
