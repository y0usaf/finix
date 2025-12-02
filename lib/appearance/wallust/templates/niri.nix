# Niri border colors template (included via niri's include directive)
# Uses theme-specific accent colors, color8 for inactive (dark grey)
''
  layout {
    border {
      on
      {% if "p4g" in wallpaper %}
      active-color "{{ color11 }}"
      {% else %}
      active-color "{{ color4 }}"
      {% endif %}
      inactive-color "{{ color8 }}"
    }
    tab-indicator {
      {% if "p4g" in wallpaper %}
      active-color "{{ color11 }}"
      {% else %}
      active-color "{{ color4 }}"
      {% endif %}
      inactive-color "{{ color8 }}"
    }
  }
''
