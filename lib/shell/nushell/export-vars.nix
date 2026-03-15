{config}: ''
  def export_vars_from_files [dir_path: string] {
    if not ($dir_path | path exists) { return }
    let skip_keys = ["ANTHROPIC_API_KEY", "OPENAI_API_KEY"]
    for file in (ls $dir_path | where type == file | get name) {
      let var_name = ($file | path basename | str replace '.txt' '''')
      if not ($var_name =~ '^[a-zA-Z_][a-zA-Z0-9_]*$') { continue }
      if ($var_name in $skip_keys) { continue }
      let content = (open $file | str trim)
      if ($content | is-empty) { continue }
      if ($content =~ '-----') { continue }
      load-env {($var_name): $content}
    }
  }
  export_vars_from_files "${config.user.homeDirectory}/Tokens"
''
