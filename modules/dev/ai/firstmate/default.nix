{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  githubHomepage = name: "https://github.com/kunchenguid/${name}";

  mkNodeTool = {
    name,
    version,
    description,
    srcHash,
    npmDepsHash,
  }:
    pkgs.buildNpmPackage {
      pname = name;
      inherit version;

      src =
        pkgs.runCommandLocal "${name}-${version}-src" {
          nativeBuildInputs = [pkgs.jq];
        } ''
          mkdir -p $out
          tar xzf ${pkgs.fetchurl {
            url = "https://registry.npmjs.org/${name}/-/${name}-${version}.tgz";
            hash = srcHash;
          }} -C $out --strip-components=1

          jq 'del(.devDependencies, .scripts)' $out/package.json > $out/package.json.new
          mv $out/package.json.new $out/package.json
          cp ${./. + "/${name}.package-lock.json"} $out/package-lock.json
        '';

      inherit npmDepsHash;

      dontNpmBuild = true;
      dontNpmPrune = true;

      meta = {
        inherit description;
        homepage = githubHomepage name;
        license = lib.licenses.mit;
        mainProgram = name;
      };
    };

  mkReleaseBinary = {
    name,
    version,
    description,
    tag ? "v${version}",
    asset,
    hash,
    dynamic ? false,
  }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = name;
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/kunchenguid/${name}/releases/download/${tag}/${name}-${tag}-${
          {
            "x86_64-linux" = asset;
          }
          .${
            system
          }
          or (throw "${name}: no release asset recorded for system '${system}'")
        }.tar.gz";
        inherit hash;
      };

      sourceRoot = ".";

      installPhase =
        if dynamic
        then ''
          runHook preInstall
          install -Dm755 ${name} $out/libexec/${name}
          mkdir -p $out/bin
          printf '%s\n' \
            '#!${pkgs.stdenv.shell}' \
            'exec ${pkgs.stdenv.cc.bintools.dynamicLinker} --library-path ${lib.makeLibraryPath [pkgs.glibc]} "${placeholder "out"}/libexec/${name}" "$@"' \
            > $out/bin/${name}
          chmod 755 $out/bin/${name}
          runHook postInstall
        ''
        else ''
          runHook preInstall
          install -Dm755 ${name} $out/bin/${name}
          runHook postInstall
        '';

      meta = {
        inherit description;
        homepage = githubHomepage name;
        license = lib.licenses.mit;
        mainProgram = name;
        platforms = ["x86_64-linux"];
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      };
    };
in {
  options.user.dev.ai.firstmate = {
    enable = lib.mkEnableOption "the runtime tools firstmate's bootstrap requires";
  };

  config = lib.mkIf config.user.dev.ai.firstmate.enable {
    environment.systemPackages = [
      pkgs.perl

      (mkNodeTool {
        name = "gh-axi";
        version = "0.1.35";
        description = "GitHub CLI shaped for AI agents";
        srcHash = "sha256-9yWr5EfJkqPWzA2aYyWGcj7RzxbHlRpAvODHPgkD5q4=";
        npmDepsHash = "sha256-NHsvrHpb+dvOef2qN1HJlpg8OAcgie3UI8BdgF1HE0o=";
      })

      (mkNodeTool {
        name = "chrome-devtools-axi";
        version = "0.1.35";
        description = "Chrome DevTools Protocol driver for AI agents";
        srcHash = "sha256-XEwivpIae2OxEGblsXWR4NfNZ+ORf706tFz5X6qwpiw=";
        npmDepsHash = "sha256-On8shW1DWU1E6Kj5+AT7ZrucpTdUizc4liRIcqKQ9TI=";
      })

      (mkNodeTool {
        name = "tasks-axi";
        version = "0.2.5";
        description = "Task queue CLI for AI agents";
        srcHash = "sha256-Vv2AUAYDdK5eD4CLRoiLq3TZasO5Tn/8C6FKSt7QozA=";
        npmDepsHash = "sha256-Ab3wASe39PBuGCjn2SA2rOAdUMs6DWzcwFOq0fww+z4=";
      })

      (mkNodeTool {
        name = "quota-axi";
        version = "0.1.49";
        description = "Provider quota and spend reporter for AI agents";
        srcHash = "sha256-UpXNEYFuTgG4qFZcJuvg7SKuW5o3RA3jEjkmebyzyQM=";
        npmDepsHash = "sha256-P+ozBxPJRGZatdX1pppZ0MtUD1tBi7rdSCg8/dhh2p8=";
      })

      (mkNodeTool {
        name = "lavish-axi";
        version = "0.1.76";
        description = "Local presentation server for agent-built review boards";
        srcHash = "sha256-LReeEz+tGwZpCEreR3TaA65eh6SCohWwZntMjP3KqVs=";
        npmDepsHash = "sha256-gu1TVpMXGPTrpkWeooon7zOfuRp0NtBWRyA7wbk+5fE=";
      })

      (mkReleaseBinary {
        name = "treehouse";
        version = "2.3.0";
        description = "Isolated per-task working copies for AI agents";
        asset = "linux-amd64";
        hash = "sha256-lP0rLCDDWqwd3ClBMXiQrYLJkW9czsusSlDNp4Pu0Q8=";
        dynamic = true;
      })

      (mkReleaseBinary {
        name = "no-mistakes";
        version = "1.79.0";
        description = "Validation pipeline that reviews, tests, and opens pull requests";
        asset = "linux-amd64";
        hash = "sha256-0XjIpRNHY7jl9tglRaOnYoX7vNwT0JAg0QkeyAo/jaY=";
      })
    ];
  };
}
