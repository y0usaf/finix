###############################################################################
# Kitty Terminal Configuration
# Fast, feature-rich terminal emulator with GPU acceleration
# - Terminal styling and appearance
# - Key bindings for clipboard operations
# - Font configuration with fallback support
# - Cursor and mouse behavior settings
###############################################################################
{
  config,
  pkgs,
  lib,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.ui.kitty;

  # Calculate the scaled font size based on the hostHome's base font size.
  computedFontSize = hostHome.cfg.appearance.baseFontSize * 1.33;

  # Get the main font name from the hostHome's font configuration
  mainFontName = (builtins.elemAt hostHome.cfg.appearance.fonts.main 0).name;

  # Get fallback font names
  fallbackFontNames = map (x: x.name) hostHome.cfg.appearance.fonts.fallback;

  # Note: Kitty handles font fallbacks automatically, so we don't need explicit symbol_map

  # Main terminal settings
  kittyMainSettings = {
    # Terminal identification
    term = "xterm-256color";

    # Font configuration - Note: font_family and font_size are handled by the font attribute
    # so we don't set them in settings to avoid conflicts

    # Cursor settings - equivalent to Foot's underline style and no blink
    cursor_shape = "underline";
    cursor_blink_interval = "0"; # 0 disables blinking (equivalent to "no")

    # Mouse behavior settings
    mouse_hide_wait = "-1"; # Never hide cursor (equivalent to hide-when-typing = "no")
    wheel_scroll_multiplier = "5.0"; # Enable smooth scrolling (similar to alternate-scroll-mode)

    # Background and foreground colors with transparency
    background_opacity = "0"; # 85% opaque, 15% transparent for nice transparency effect
    background = "#000000";
    foreground = "#ffffff";

    # Regular color palette (colors 0-7)
    color0 = "#000000"; # black
    color1 = "#ff0000"; # red
    color2 = "#00ff00"; # green
    color3 = "#ffff00"; # yellow
    color4 = "#1e90ff"; # blue
    color5 = "#ff00ff"; # magenta
    color6 = "#00ffff"; # cyan
    color7 = "#ffffff"; # white

    # Bright color palette (colors 8-15)
    color8 = "#808080"; # bright black
    color9 = "#ff0000"; # bright red
    color10 = "#00ff00"; # bright green
    color11 = "#ffff00"; # bright yellow
    color12 = "#1e90ff"; # bright blue
    color13 = "#ff00ff"; # bright magenta
    color14 = "#00ffff"; # bright cyan
    color15 = "#ffffff"; # bright white

    # Window settings
    window_padding_width = "0";
    confirm_os_window_close = "0";

    # Performance settings
    repaint_delay = "10";
    input_delay = "3";
    sync_to_monitor = "yes";
  };

  # Key bindings: assign shortcuts for clipboard copy and paste actions
  kittyKeyBindings = {
    "ctrl+c" = "copy_to_clipboard";
    "ctrl+v" = "paste_from_clipboard";
  };

  # Extra configuration for additional features
  kittyExtraConfig = ''
    # Audio and visual bell settings
    enable_audio_bell no
    visual_bell_duration 0.0
    window_alert_on_bell no
    bell_on_tab "🔔 "

    # Tab bar configuration
    tab_bar_edge bottom
    tab_bar_style powerline
    tab_powerline_style slanted

    # Window management
    remember_window_size yes
    initial_window_width 1280
    initial_window_height 720
  '';
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.ui.kitty = {
    enable = lib.mkEnableOption "kitty terminal emulator";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Required Packages
    ###########################################################################
    home.packages = with pkgs; [
      tty-clock
      nitch
    ];

    ###########################################################################
    # Kittens (Custom Extensions)
    ###########################################################################
    xdg.configFile."kitty/kittens/panel.py" = {
      text = ''#!/usr/bin/env python3
"""
System Panel Kitten - A proper kitty kitten
Shows system information and clock using kitty's TUI framework
"""

import subprocess
import time
from datetime import datetime
from typing import List, Optional

from kittens.tui.handler import result_handler
from kittens.tui.loop import Loop
from kittens.tui.operations import styled
from kitty.utils import screen_size_function


class SystemPanel:
    def __init__(self, loop: Loop) -> None:
        self.loop = loop
        self.quit_loop = False
        
    def get_system_info(self) -> str:
        """Get system info from nitch"""
        try:
            result = subprocess.run(['nitch'], capture_output=True, text=True, timeout=3)
            return result.stdout.strip()
        except Exception:
            return "System info unavailable"
    
    def format_time(self) -> List[str]:
        """Format current time for display"""
        now = datetime.now()
        time_str = now.strftime("%H:%M:%S")
        date_str = now.strftime("%A, %B %d, %Y")
        
        return [
            "╔═══════════════════════════╗",
            f"║      {time_str}          ║",
            f"║   {date_str}   ║",
            "╚═══════════════════════════╝",
        ]
    
    def render(self) -> None:
        """Render the panel"""
        screen = self.loop.screen
        screen.cursor.x = 0
        screen.cursor.y = 0
        screen.erase_in_display(0, False)  # Clear screen
        
        lines = []
        
        # Header
        lines.append(styled("═" * 50, fg='cyan', bold=True))
        lines.append(styled("     🖥️  SYSTEM PANEL  ⏰     ", fg='cyan', bold=True))
        lines.append(styled("═" * 50, fg='cyan', bold=True))
        lines.append("")
        
        # Time display
        time_lines = self.format_time()
        for line in time_lines:
            lines.append(styled(line, fg='yellow', bold=True))
        lines.append("")
        
        # System info
        lines.append(styled("📊 System Information:", fg='green', bold=True))
        lines.append(styled("─" * 50, fg='cyan'))
        
        info = self.get_system_info()
        for line in info.split('\n'):
            if line.strip():
                lines.append(f"  {line}")
        
        lines.append("")
        lines.append(styled("─" * 50, fg='cyan'))
        lines.append(styled("Press 'q' to quit or any key to refresh", fg='bright_black'))
        
        # Write to screen
        for i, line in enumerate(lines):
            screen.cursor.y = i
            screen.cursor.x = 0
            screen.write(line)
            screen.carriage_return()
            screen.linefeed()
    
    def on_key(self, key_event) -> None:
        """Handle key press events"""
        if key_event.key == 'q' or key_event.key == 'ESCAPE':
            self.quit_loop = True
            self.loop.quit()
        else:
            # Refresh on any other key
            self.render()
    
    def on_interrupt(self) -> None:
        """Handle interrupt signal"""
        self.quit_loop = True
        self.loop.quit()


def main(args: List[str]) -> Optional[str]:
    """Main entry point for the kitten"""
    
    def handle_result(ans: str, target_window_id: int, boss) -> None:
        pass
    
    from kittens.tui.loop import Loop
    
    loop = Loop()
    handler = SystemPanel(loop)
    
    # Set up event handlers
    loop.loop.on_key_event = handler.on_key
    loop.loop.on_interrupt = handler.on_interrupt
    
    # Auto-refresh every second
    def refresh():
        if not handler.quit_loop:
            handler.render()
            loop.call_later(1, refresh)
    
    # Initial render and start refresh cycle
    handler.render()
    loop.call_later(1, refresh)
    
    # Start the event loop
    loop.loop()
    
    return None


@result_handler(no_ui=True)
def handle_result(args: List[str], ans: str, target_window_id: int, boss) -> None:
    """Handle the result when kitten exits"""
    pass


if __name__ == '__main__':
    import sys
    main(sys.argv[1:])
'';
      executable = true;
    };

    ###########################################################################
    # Programs
    ###########################################################################
    programs.kitty = {
      enable = true;

      # Font configuration
      font = {
        name = mainFontName;
        size = computedFontSize;
      };

      # Main settings
      settings = kittyMainSettings;

      # Key bindings
      keybindings = kittyKeyBindings;

      # Additional configuration
      extraConfig = kittyExtraConfig;

      # Shell integration
      shellIntegration = {
        enableZshIntegration = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
      };
    };
  };
}
