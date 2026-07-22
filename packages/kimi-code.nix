{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  nodejs_24,
  makeWrapper,
  ripgrep,
  fd,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "kimi-code";
  version = "0.28.1";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "MoonshotAI";
    repo = "kimi-code";
    tag = "@moonshot-ai/kimi-code@${finalAttrs.version}";
    hash = "sha256-Mjf4jwarwD5S6pEo4n145GQ/DnNsdzBT4OFm5VXLRlA=";
  };

  pnpmWorkspaces = [
    "."
    "@moonshot-ai/acp-adapter"
    "@moonshot-ai/agent-core"
    "@moonshot-ai/agent-core-v2"
    "@moonshot-ai/kap-server"
    "@moonshot-ai/kaos"
    "@moonshot-ai/kosong"
    "@moonshot-ai/migration-legacy"
    "@moonshot-ai/minidb"
    "@moonshot-ai/kimi-code-sdk"
    "@moonshot-ai/kimi-code-oauth"
    "@moonshot-ai/klient"
    "@moonshot-ai/pi-tui"
    "@moonshot-ai/protocol"
    "@moonshot-ai/kimi-telemetry"
    "@moonshot-ai/transcript"
    "@moonshot-ai/kimi-code"
    "kimi-code"
    "@moonshot-ai/kimi-inspect"
    "@moonshot-ai/kimi-web"
    "@moonshot-ai/vis"
    "@moonshot-ai/vis-server"
    "@moonshot-ai/vis-web"
    "kimi-code-docs"
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src pnpmWorkspaces;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-+pzJfoWJwVXIUU8oc56LVpfNjSY6MABID5g11Cm92xw=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm_10
    pnpmConfigHook
    makeWrapper
  ];

  env.KIMI_CODE_BUILD_TARGET = "linux-x64";

  buildPhase = ''
    runHook preBuild

    # SEA blob step embeds web assets from apps/kimi-code/dist-web;
    # build web app and stage assets before producing native executable.
    pnpm --filter=@moonshot-ai/kimi-web run build
    node apps/kimi-code/scripts/copy-web-assets.mjs
    pnpm --filter=@moonshot-ai/kimi-code run build:native:sea

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 \
      "apps/kimi-code/dist-native/bin/linux-x64/kimi" \
      "$out/bin/kimi"

    runHook postInstall
  '';

  dontStrip = true;

  postInstall = ''
    wrapProgram $out/bin/kimi \
      --prefix PATH : ${lib.makeBinPath [ripgrep fd]}
  '';

  meta = {
    description = "Kimi Code CLI — AI coding agent for the terminal";
    homepage = "https://github.com/MoonshotAI/kimi-code";
    license = lib.licenses.mit;
    mainProgram = "kimi";
    platforms = ["x86_64-linux"];
  };
})
