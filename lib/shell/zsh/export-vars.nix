{config}: ''
  export_vars_from_files() {
      local dir_path=$1

      if [[ ! -d "$dir_path" ]]; then
          return 0
      fi

      local skip_for_opencode=("ANTHROPIC_API_KEY" "OPENAI_API_KEY")

      for file_path in "$dir_path"/*; do
          if [[ -f $file_path ]]; then
              var_name=$(basename "$file_path" .txt)

              if [[ ! $var_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                  continue
              fi

              if [[ " ''${skip_for_opencode[@]} " =~ " $var_name " ]]; then
                  continue
              fi

              local content=$(cat "$file_path" 2>/dev/null || echo "")
              if [[ -z "$content" ]] || [[ $content =~ [[:cntrl:]] ]] || [[ $content == *"-----"* ]]; then
                  continue
              fi

              export $var_name="$content"
          fi
      done
  }
  export_vars_from_files "${config.user.tokensDirectory}"
''
