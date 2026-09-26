{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  # firstmate's own bootstrap (bin/fm-bootstrap.sh) refuses to dispatch work
  # until every tool below is on PATH at or above its version floor, and it
  # reports each one it cannot find. Declaring them here keeps that list
  # satisfied from the system generation instead of from a hand-run
  # `npm install -g`, which on an impermanent root has nowhere to survive.
  #
  # Bumping a version: change `version`, refresh the two hashes (nix build
  # reports the expected one on mismatch), and for an npm tool regenerate the
  # matching *.package-lock.json beside this module with
  #   npm install --package-lock-only --omit=dev
  # run over that release's package.json with its scripts and devDependencies
  # removed (see mkNodeTool's preprocessing, which does the same at build time).
  githubHomepage = name: "https://github.com/kunchenguid/${name}";

  # The axi family publishes compiled JavaScript to npm and nothing else, so
  # the published tarball is the source: no toolchain, no dev dependencies, and
  # no build step. Preprocessing drops the dev-only fields npm would otherwise
  # refuse to reconcile with the committed production lockfile and the build
  # scripts whose sources the tarball does not ship.
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

      # `dist/` is already compiled, and `npm ci` installed exactly the
      # production dependencies the lockfile pins.
      dontNpmBuild = true;
      dontNpmPrune = true;

      meta = {
        inherit description;
        homepage = githubHomepage name;
        license = lib.licenses.mit;
        mainProgram = name;
      };
    };

  # A single-file release binary, wired for the platform whose asset this
  # flake is carrying; the `throw` keeps a second host from silently
  # evaluating to the wrong architecture's download.
  mkReleaseBinary = {
    name,
    version,
    description,
    tag ? "v${version}",
    asset,
    hash,
    # Upstream links this one against the FHS loader path and libc; see the
    # installPhase for why it is not simply patchelf'd into place.
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

      # patchelf cannot be used here for the dynamically linked one: growing
      # this Go binary's program headers to hold a store-length interpreter
      # path relocates its segments and the result segfaults on startup. The
      # untouched binary runs correctly under the NixOS loader, so hand it the
      # loader and a library search path instead of rewriting it.
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
    # tmux is the same dependency set's other half; it lives in
    # modules/tools/tmux.nix because it is usable without firstmate.
    #
    # perl is not in that list but is load-bearing all the same: the backlog
    # transition and session-start libraries decode and re-encode byte values
    # with it, so dispatch and cleanup fail loudly without it.
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

      # Upstream builds this one against the FHS loader path and links libc,
      # neither of which exists here.
      (mkReleaseBinary {
        name = "treehouse";
        version = "2.3.0";
        description = "Isolated per-task working copies for AI agents";
        asset = "linux-amd64";
        hash = "sha256-lP0rLCDDWqwd3ClBMXiQrYLJkW9czsusSlDNp4Pu0Q8=";
        dynamic = true;
      })

      # Statically linked, and its version gate is a structured-attestation
      # check, so firstmate needs 1.46.0 or newer.
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
