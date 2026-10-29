{
  config,
  lib,
  pkgs,
  ...
}: let
  version = "0.9.7";
  build = "20261028-175324-c2f7563";

  src = pkgs.requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    hashMode = "flat";
    hash = "sha256-DPKeJdibqTNIy/YsryEX6AbCSR+RNAt+sfxo2AqE5jg=";
    message = ''
      Tern ${version} is a closed-beta build behind a Stencil account. Sign in
      at https://stencil.so/tern, download

        https://build.stencil.so/d/tern/${build}/Tern-${version}-linux-x86_64.tar.gz

      from the browser session that is signed in, then:

        nix-store --add-fixed sha256 Tern-${version}-linux-x86_64.tar.gz

      A new build needs both this URL's build id and the hash above.
    '';
  };

  tern =
    pkgs.stdenv.mkDerivation {
      pname = "tern";
      inherit version src;

      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [pkgs.stdenv.cc.cc.lib];
      runtimeDependencies = with pkgs; [
        wayland
        libxkbcommon
        vulkan-loader
        libglvnd
        linux-pam
      ];

      installPhase = ''
        runHook preInstall
        install -Dm755 tern $out/bin/tern
        runHook postInstall
      '';

      meta = {
        description = "Tern, Stencil's GPU multiplexing terminal";
        homepage = "https://stencil.so/tern";
        mainProgram = "tern";
        platforms = ["x86_64-linux"];
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      };
    };
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/tern"
    ".local/state/tern"
  ];

  environment.systemPackages = [tern];
}
