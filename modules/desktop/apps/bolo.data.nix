{
  model = {
    name = "parakeet-v3-int8";
    engine = "sherpa-onnx-transducer";
    url = "https://huggingface.co/csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/resolve/main";
    hashes = {
      "encoder.int8.onnx" = "sha256-rPwrRFY3fhXQTwJDr1QLf+fJkvjYmNdRzxNMOlX9Ikc=";
      "decoder.int8.onnx" = "sha256-F55QxD0aneeciiQUmi+brG61mBgj8qLtiNZVskJI204=";
      "joiner.int8.onnx" = "sha256-MWTBP8KCEAlEDSD8tf3Hi/8otNsvjQ8LMpEBcZwJSLM=";
      "tokens.txt" = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
    };
  };
  vocabulary = {
    Hyprland = ["hyper land" "hipper land"];
    niri = ["neary" "nyree"];
    y0usaf = ["you sef" "yousef" "you saf"];
    "sherpa-onnx" = ["sherpa onyx" "sherpa onix"];
    tomoe = ["toe moe" "tomo eh"];
    ekko = ["eck oh" "eh ko"];
    moon = [];
    finix = ["fee nix" "finnix" "fi nix"];
  };
}
