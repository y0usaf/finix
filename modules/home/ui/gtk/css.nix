{
  config,
  lib,
  ...
}: let
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;
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
  repeatedShadow = lib.concatStringsSep ",\n" (lib.concatLists (lib.genList (_: shadowOffsets) 4));
  opacity = toString config.home.core.appearance.opacity;
  whiteColor = "white";
  backgroundColor = "rgba(0, 0, 0, ${opacity})";
  menuBackground = "rgba(0, 0, 0, ${opacity})";
  hoverBg = "rgba(100, 149, 237, 0.1)";
  selectedBg = "rgba(100, 149, 237, 0.5)";
in {
  gtkCss = ''
    /* Global element styling */
    * {
      font-family: "${mainFontName}";
      color: ${whiteColor};
      background: ${backgroundColor};
      outline-width: 0;
      outline-offset: 0;
      text-shadow: ${repeatedShadow};
    }
    /* Hover state for all elements */
    *:hover {
      background: ${hoverBg};
    }
    /* Selected state for all elements */
    *:selected {
      background: ${selectedBg};
    }
    /* Button styling */
    button {
      border-radius: 0.15rem;
      min-height: 1rem;
      padding: 0.05rem 0.25rem;
    }
    /* Menu background styling */
    menu {
      background: ${menuBackground};
    }
  '';
}
