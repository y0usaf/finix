_: {
  history = ''
    $env.config.history = {
      max_size: 10000
      file_format: "sqlite"
      sync_on_enter: true
      isolation: false
    }
  '';

  completion = ''
    $env.config.completions = {
      case_sensitive: false
      quick: true
      partial: true
      algorithm: "fuzzy"
      use_ls_colors: true
    }
  '';

  prompt = ''
    $env.PROMPT_COMMAND = {||
      let path = ($env.PWD | str replace $env.HOME '~')
      $"(ansi green_bold)($path)(ansi reset)"
    }
    $env.PROMPT_COMMAND_RIGHT = ""
    $env.PROMPT_INDICATOR = {||
      if ($env.LAST_EXIT_CODE == 0) {
        $"(ansi cyan_bold)>(ansi reset) "
      } else {
        $"(ansi red_bold)>(ansi reset) "
      }
    }
    $env.PROMPT_INDICATOR_VI_INSERT = "> "
    $env.PROMPT_INDICATOR_VI_NORMAL = "〉"
    $env.PROMPT_MULTILINE_INDICATOR = "::: "
  '';

  carapace = ''
    $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
    source ~/.config/nushell/carapace.nu
  '';

  keybindings = ''
    $env.config.keybindings = [
      {
        name: completion_menu
        modifier: none
        keycode: tab
        mode: [emacs vi_normal vi_insert]
        event: {
          until: [
            { send: menu name: completion_menu }
            { send: menunext }
            { edit: complete }
          ]
        }
      }
      {
        name: history_menu
        modifier: control
        keycode: char_r
        mode: [emacs vi_normal vi_insert]
        event: { send: menu name: history_menu }
      }
    ]
  '';
}
