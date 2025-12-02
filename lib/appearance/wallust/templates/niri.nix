# Niri border colors template (included via niri's include directive)
# Uses color4 for active (accent), color8 for inactive (dark grey)
''
  layout {
    border {
      on
      active-color "{{ color4 }}"
      inactive-color "{{ color8 }}"
    }
    tab-indicator {
      active-color "{{ color4 }}"
      inactive-color "{{ color8 }}"
    }
  }
''
