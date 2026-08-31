# GPU Whisper STT (faster-whisper/ctranslate2) as a finit service on the
# desktop's RTX 4090, exposing an OpenAI-compatible audio API.
#
# The Hermes gateway runs on y0usaf-server (CPU-only) and delegates
# speech-to-text here over the tailnet: server-side stt.provider=openai with
# an OpenAI-compatible base URL pointed at this listener. Surface is exactly
# what an OpenAI SDK client needs: GET /health and POST
# /v1/audio/transcriptions (multipart field "file", optional "language"
# form field), replying {"text": ...}.
#
# CUDA: this host evaluates with cudaSupport = true (modules/finix/
# default.nix desktopPersistent), so python3Packages.ctranslate2 is the
# CUDA build; the server pins device="cuda", compute_type="float16",
# model large-v3 (override via the WHISPER_MODEL env, read by the Python
# source below).
#
# State: faster-whisper caches downloaded models under $HOME/.cache — the
# dedicated whisper-stt user's home is /var/lib/whisper-stt, allowlisted in
# hosts/y0usaf-desktop/impermanence.nix (finix has no systemd StateDirectory;
# the /persist bind replays it).
{
  lib,
  pkgs,
  ...
}: let
  whisperPython = pkgs.python3.withPackages (ps: [
    ps.faster-whisper
    ps.flask
  ]);

  # Server source lives OUT of the finit command string (pkgs.writeText, the
  # same pattern hermes.nix uses for patched upstream nix) so the command
  # stays free of Python quoting.
  whisperServer = pkgs.writeText "whisper-stt-server.py" ''
    """OpenAI-compatible Whisper STT server (faster-whisper, CUDA).

    Endpoints: GET /health, POST /v1/audio/transcriptions. Multipart field
    "file" (audio), optional form field "language". Replies {"text": ...},
    shaped close enough to the OpenAI audio API for an OpenAI SDK client.
    """

    import json
    import os
    import tempfile

    from flask import Flask, request

    app = Flask(__name__)

    MODEL_SIZE = os.environ.get("WHISPER_MODEL", "large-v3")
    _model = None


    def model():
        global _model
        if _model is None:
            from faster_whisper import WhisperModel

            _model = WhisperModel(MODEL_SIZE, device="cuda", compute_type="float16")
        return _model


    @app.get("/health")
    def health():
        return json.dumps({"status": "ok"})


    @app.post("/v1/audio/transcriptions")
    def transcribe():
        if "file" not in request.files:
            return (
                json.dumps(
                    {
                        "error": {
                            "message": "no audio file in request (multipart field 'file')",
                            "type": "invalid_request_error",
                        }
                    }
                ),
                400,
            )
        language = request.form.get("language") or None
        suffix = os.path.splitext(request.files["file"].filename or "audio.wav")[1]
        if not suffix:
            suffix = ".wav"
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            request.files["file"].save(tmp.name)
            path = tmp.name
        try:
            segments, info = model().transcribe(path, language=language)
            text = "".join(segment.text for segment in segments)
        finally:
            os.unlink(path)
        return json.dumps({"text": text})


    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=8517, threaded=True)
  '';
in {
  users = {
    users.whisper-stt = {
      isSystemUser = true;
      group = "whisper-stt";
      home = "/var/lib/whisper-stt";
    };
    groups.whisper-stt = {};
  };

  finit.services.whisper-stt = {
    description = "whisper-stt: OpenAI-compatible faster-whisper STT (GPU)";
    user = "whisper-stt";
    group = "whisper-stt";
    command = "${pkgs.writeShellScript "whisper-stt-start" ''
      exec ${whisperPython}/bin/python ${whisperServer}
    ''}";
    environment.HOME = "/var/lib/whisper-stt";
    conditions = ["net/lo/up"];
    log = true;
  };
}
