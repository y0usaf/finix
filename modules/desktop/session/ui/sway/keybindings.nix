{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.sway.enable {
    bayt.users."${config.user.name}".files.".config/sway/config".text = lib.mkAfter ''
      bindsym $mod+Shift+slash exec swaynag -t warning -m 'Hotkey overlay unavailable in sway; see ~/.config/sway/config'
      bindsym $mod+Shift+e exit
      ${lib.optionalString (config.user.ui.quickshell.enable or false) "bindsym $mod+o exec quickshell ipc call workspaces toggle"}

      bindsym $mod+t exec $term
      bindsym $mod2+r exec $launcher
      bindsym $mod+e exec $filemanager
      bindsym $mod2+Shift+o exec $notepad

      bindsym $mod+q kill
      bindsym $mod+f fullscreen toggle
      bindsym $mod+Shift+f fullscreen toggle global
      bindsym $mod+space focus mode_toggle
      bindsym $mod2+space floating toggle

      bindsym $mod+h focus left
      bindsym $mod+l focus right
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+Left focus left
      bindsym $mod+Right focus right
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up

      bindsym $mod+Shift+h move left
      bindsym $mod+Shift+l move right
      bindsym $mod+Shift+j move down
      bindsym $mod+Shift+k move up
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Right move right
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up

      bindsym $mod+Page_Up workspace prev_on_output
      bindsym $mod+Page_Down workspace next_on_output
      bindsym $mod+u workspace prev_on_output
      bindsym $mod+i workspace next_on_output
      bindsym $mod2+1 workspace number 1
      bindsym $mod2+2 workspace number 2
      bindsym $mod2+3 workspace number 3
      bindsym $mod2+4 workspace number 4
      bindsym $mod2+5 workspace number 5
      bindsym $mod2+6 workspace number 6
      bindsym $mod2+7 workspace number 7
      bindsym $mod2+8 workspace number 8
      bindsym $mod2+9 workspace number 9

      bindsym $mod+Ctrl+Page_Up move container to workspace prev_on_output
      bindsym $mod+Ctrl+Page_Down move container to workspace next_on_output
      bindsym $mod+Ctrl+u move container to workspace prev_on_output
      bindsym $mod+Ctrl+i move container to workspace next_on_output
      bindsym $mod2+Shift+1 move container to workspace number 1
      bindsym $mod2+Shift+2 move container to workspace number 2
      bindsym $mod2+Shift+3 move container to workspace number 3
      bindsym $mod2+Shift+4 move container to workspace number 4
      bindsym $mod2+Shift+5 move container to workspace number 5
      bindsym $mod2+Shift+6 move container to workspace number 6
      bindsym $mod2+Shift+7 move container to workspace number 7
      bindsym $mod2+Shift+8 move container to workspace number 8
      bindsym $mod2+Shift+9 move container to workspace number 9

      mode "resize" {
          bindsym h resize shrink width 10 px
          bindsym l resize grow width 10 px
          bindsym j resize grow height 10 px
          bindsym k resize shrink height 10 px
          bindsym Left resize shrink width 10 px
          bindsym Right resize grow width 10 px
          bindsym Down resize grow height 10 px
          bindsym Up resize shrink height 10 px
          bindsym Return mode "default"
          bindsym Escape mode "default"
      }
      bindsym $mod+r mode "resize"
      bindsym $mod+Shift+r layout toggle split
      bindsym $mod+comma layout stacking
      bindsym $mod+period layout tabbed
      bindsym $mod+bracketleft splith
      bindsym $mod+bracketright splitv

      bindsym $mod+1 exec $ide
      bindsym $mod+2 exec $browser
      bindsym $mod+3 exec $discord
      bindsym $mod+4 exec steam
      bindsym $mod+5 exec $obs

      bindsym $mod+g exec sh -c 'grim -g "$(slurp -d)" - | wl-copy -t image/png'
      bindsym $mod+Shift+g exec sh -c 'grim - | wl-copy -t image/png'

      bindsym $mod+grave exec hyprpicker -a
      bindsym $mod+Shift+c exec sh -c 'killall swaybg 2>/dev/null; swaybg -i $(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1) -m fill &'

      bindsym --locked XF86MonBrightnessUp exec brightnessctl set 5%+
      bindsym --locked XF86MonBrightnessDown exec brightnessctl set 5%-

      bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

      bindsym --locked XF86AudioPlay exec playerctl play-pause
      bindsym --locked XF86AudioNext exec playerctl next
      bindsym --locked XF86AudioPrev exec playerctl previous

      bindsym $mod+6 exec sh -c 'swaymsg output DP-4 enable; swaymsg output DP-2 enable; swaymsg output HDMI-A-2 enable'
      bindsym $mod+7 exec sh -c 'swaymsg output DP-4 disable; swaymsg output DP-2 disable; swaymsg output HDMI-A-2 disable'
    '';
  };
}
