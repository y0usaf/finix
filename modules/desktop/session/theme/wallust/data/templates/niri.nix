# Niri border colors template (included via niri's include directive)
# Uses cursor color as accent (cursor == accent in our colorschemes), color8 for inactive
''
  layout {
    border {
      on
      active-color "{{ cursor }}"
      inactive-color "{{ color8 }}"
    }
    tab-indicator {
      active-color "{{ cursor }}"
      inactive-color "{{ color8 }}"
    }
  }
''
