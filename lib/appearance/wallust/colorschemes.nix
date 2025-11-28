# Shared wallust colorschemes for NixOS and Darwin
{
  # Maximum Dopamine - Cyberpunk/Synthwave Neon
  # High saturation, high contrast, pure visual stimulation
  dopamine = {
    colors = {
      color0 = "#0a0a0f"; # Void black (maximum contrast base)
      color1 = "#ff006e"; # Hot pink (dopamine red)
      color2 = "#00ff88"; # Acid lime (electric green)
      color3 = "#ffbe0b"; # Gold (warm reward)
      color4 = "#00d9ff"; # Cyan neon (cool stimulation)
      color5 = "#c71585"; # Deep magenta (rich)
      color6 = "#00ffb3"; # Aqua (fresh electric)
      color7 = "#e0e0ff"; # Pale lavender
      color8 = "#1a1a2e"; # Dark gray-blue (secondary bg)
      color9 = "#ff0055"; # NEON PINK (peak stimulation)
      color10 = "#00ff99"; # NEON GREEN (iconic cyberpunk)
      color11 = "#ffcc00"; # BRIGHT GOLD (high saturation)
      color12 = "#00e5ff"; # ELECTRIC CYAN (peak neon)
      color13 = "#ff00ff"; # PURE MAGENTA (vaporwave core)
      color14 = "#00ffff"; # FULL CYAN (aqua neon)
      color15 = "#ffffff"; # Pure white (highest contrast)
    };
    special = {
      background = "#0a0a0f"; # Void black
      foreground = "#f0f0ff"; # Bright white
      cursor = "#ff006e"; # Hot pink cursor (reward on every keystroke)
    };
  };

  sunset-red = {
    colors = {
      color0 = "#1a0a0a";
      color1 = "#ff4444";
      color2 = "#ff7744";
      color3 = "#ffaa44";
      color4 = "#cc6644";
      color5 = "#aa4444";
      color6 = "#ff8866";
      color7 = "#ddaa88";
      color8 = "#553333";
      color9 = "#ff6666";
      color10 = "#ff9966";
      color11 = "#ffbb66";
      color12 = "#dd8866";
      color13 = "#cc6666";
      color14 = "#ffaa88";
      color15 = "#ffddcc";
    };
    special = {
      background = "#1a0a0a";
      foreground = "#ddaa88";
      cursor = "#ff6644";
    };
  };
}
