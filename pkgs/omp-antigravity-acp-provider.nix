{pkgs}: let
  inherit (pkgs) lib;
  name = "omp-antigravity-acp-provider";
  version = "0.2.1";
  serverVersion = "1.5.0";
  server = pkgs.stdenvNoCC.mkDerivation {
    pname = "agy-acp-server";
    version = serverVersion;
    src = pkgs.fetchurl {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${serverVersion}-linux-x86_64.zip";
      hash = "sha256-NvNz6JSO3xcns5x9YrVyLWpEdL39crBK09be9XGAjJ8=";
    };
    nativeBuildInputs = [pkgs.unzip pkgs.patchelf];
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 agy_acp_server.par $out/libexec/agy-acp/agy_acp_server.par
      install -Dm755 localharness_external $out/libexec/agy-acp/localharness_external
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/libexec/agy-acp/agy_acp_server.par
      runHook postInstall
    '';
    dontFixup = true;
    meta = {
      description = "Google Antigravity ACP server";
      homepage = "https://antigravity.google/docs/ide/extensions";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  };
in
  pkgs.buildNpmPackage {
    pname = name;
    inherit version;
    src =
      pkgs.runCommandLocal "${name}-${version}-src" {
        nativeBuildInputs = [pkgs.jq];
      } ''
        mkdir -p $out
        tar xzf ${pkgs.fetchurl {
          url = "https://registry.npmjs.org/@n1netynine99/${name}/-/${name}-${version}.tgz";
          hash = "sha512-S3vFbOfCqUODvNNaL7uvSTJ68LDQ8wQg9XK9KI3p/K4s9qMZd3XxtK0+XB92g8tli50dAwiyHHiK8gnrm5czNQ==";
        }} -C $out --strip-components=1
        jq 'del(.devDependencies, .scripts) | .dependencies = {"proper-lockfile": "4.1.2"}' $out/package.json > $out/package.json.new
        mv $out/package.json.new $out/package.json
        cp ${../locks/omp-antigravity-acp-provider.package-lock.json} $out/package-lock.json
      '';
    npmDepsHash = "sha256-b/jTJ4TW3Dk3dFMcOVrky9ldp41Jd4VmdNmo2pZLY5E=";
    dontNpmBuild = true;
    postPatch = ''
      substituteInPlace extension/index.ts --replace-fail \
        'export default async function (pi: OmpHostApi) {' \
        'export default async function (pi: OmpHostApi) {
        process.env.AGY_ACP_BIN ||= "${server}/libexec/agy-acp/agy_acp_server.par";'
      substituteInPlace extension/runtime.mjs --replace-fail \
        'const override = explicit || env.NODE;' \
        'const override = explicit || env.NODE || "${pkgs.nodejs}/bin/node";'
      substituteInPlace extension/runtime.mjs --replace-fail \
        'return `''${FORCE_FILE_STORAGE_ENV} set by the user`;' \
        'return `''${FORCE_FILE_STORAGE_ENV} is set, so each login stays in its GEMINI_HOME folder`;'
      # Crest signs each Antigravity account in inside its own folder and pins
      # the ACP server to the file store with AGY_ACP_FORCE_FILE_STORAGE. The
      # shared Secret Service item then belongs to a different account, so this
      # adapter must neither read it nor clear it for a folder account.
      substituteInPlace extension/auth-sync.ts --replace-fail \
        'const execFileAsync = promisify(execFile);' \
        'const execFileAsync = promisify(execFile);

function crestFileStorage(env: NodeJS.ProcessEnv = process.env): boolean {
  return Boolean(env.AGY_ACP_FORCE_FILE_STORAGE?.trim());
}'
      substituteInPlace extension/auth-sync.ts --replace-fail \
        '  async removeStoredCredentialsDurably(): Promise<CredentialRemoval> {' \
        '  async removeStoredCredentialsDurably(): Promise<CredentialRemoval> {
    // A folder login never owns the keyring entry; clearing it would sign the
    // keyring account out.
    if (crestFileStorage()) return { keychainRemoved: undefined, keyringRemoved: undefined };'
      substituteInPlace extension/auth-sync.ts --replace-fail \
        '  if ((await secretService.present()) === true) {' \
        '  if (!crestFileStorage(env) && (await secretService.present()) === true) {'
      substituteInPlace extension/auth-sync.ts --replace-fail \
        '  if (fromFile) return fromFile;' \
        '  if (fromFile) return fromFile;
  if (crestFileStorage()) return undefined;'
    '';
    meta = {
      description = "Google Antigravity ACP provider for OMP";
      homepage = "https://github.com/00lllooolll00/omp-antigravity-acp-provider";
      license = lib.licenses.mit;
    };
  }
