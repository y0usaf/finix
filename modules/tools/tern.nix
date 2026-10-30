{
  config,
  lib,
  pkgs,
  ...
}: let
  version = "0.9.7";
  build = "20261028-175324-c2f7563";

  wpewebkit = import ../../pkgs/wpewebkit.nix {inherit pkgs;};

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

      nativeBuildInputs = [pkgs.autoPatchelfHook pkgs.makeWrapper];
      buildInputs = [pkgs.stdenv.cc.cc.lib];
      runtimeDependencies = with pkgs; [
        wayland
        libxkbcommon
        vulkan-loader
        libglvnd
        linux-pam
        webkitgtk_4_1
        libwpe-fdo
        wpewebkit
      ];

      installPhase = ''
        runHook preInstall
        install -Dm755 tern $out/bin/tern
        wrapProgram $out/bin/tern --prefix GIO_EXTRA_MODULES : ${pkgs.glib-networking}/lib/gio/modules --prefix PATH : ${lib.makeBinPath [pkgs.bubblewrap]}
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

  registration =
    pkgs.runCommand "tern-registration" {} ''
      export HOME=$TMPDIR/home
      export XDG_DATA_HOME=$HOME/.local/share
      export XDG_CONFIG_HOME=$HOME/.config
      export XDG_CACHE_HOME=$HOME/.cache
      export XDG_STATE_HOME=$HOME/.local/state
      mkdir -p "$HOME"
      ${tern}/bin/tern register > /dev/null

      install -d $out/share
      cp -r "$XDG_DATA_HOME/applications" "$XDG_DATA_HOME/icons" $out/share/
      substituteInPlace $out/share/applications/*.desktop --replace-fail "/bin/.tern-wrapped" "/bin/tern"
    '';

  package = pkgs.symlinkJoin {
    name = "tern-${version}";
    paths = [tern registration];
  };

  configDir = ./tern;

  files = lib.listToAttrs (map (file: {
    name = ".config/tern/${lib.removePrefix "${toString configDir}/" (toString file)}";
    value = {
      type = "copy";
      clobber = false;
      force = false;
      permissions = "0644";
      source = file;
    };
  }) (lib.filesystem.listFilesRecursive configDir));
in {
  environment.variables.GIO_EXTRA_MODULES = lib.mkDefault "${pkgs.glib-networking}/lib/gio/modules";

  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/tern"
    ".local/state/tern"
  ];

  manzil.users."${config.user.name}".files = files;

  environment.systemPackages = [package];
}
