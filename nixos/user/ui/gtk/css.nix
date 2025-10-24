{
  config,
  lib,
  ...
}: let
  mainFontName = config.user.ui.fonts.mainFontName;
  shadowSize = "0.05rem";
  shadowRadius = "0.05rem";
  shadowColor = "rgba(0, 0, 0, 0.3)";
  shadowOffsets = [
    "${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "-${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "0 ${shadowSize} ${shadowRadius} ${shadowColor}"
    "0 -${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
  ];
  strokeLayers = 4;
  repeatedShadow = lib.concatStringsSep ",\n" (lib.concatLists (lib.genList (_: shadowOffsets) strokeLayers));
  baseOpacity = toString (config.user.appearance.opacity / 3);
  textColor = "white";
  backgroundColor = "rgba(0, 0, 0, ${baseOpacity})";
in {
  gtkCss = ''
    /* Global element styling */
    * {
      font-family: "${mainFontName}";
      color: ${textColor};
      background: ${backgroundColor};
      outline-width: 0;
      outline-offset: 0;
      text-shadow: ${repeatedShadow};
    }
    /* Hover state for all elements */
    *:hover {
      background: rgba(100, 149, 237, 0.1);
    }
    /* Selected state for all elements */
    *:selected {
      background: rgba(100, 149, 237, 0.5);
    }
    /* Button styling */
    button {
      border-radius: 0.15rem;
      min-height: 1rem;
      padding: 0.05rem 0.25rem;
    }
    /* Menu background styling */
    menu {
      background: ${backgroundColor};
    }
  '';
}
