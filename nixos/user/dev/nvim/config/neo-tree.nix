{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = lib.mkAfter ''
        -- Neo-tree setup
        require("neo-tree").setup({
          close_if_last_window = true,
          popup_border_style = "rounded",
          enable_git_status = true,
          enable_diagnostics = true,
          default_component_configs = {
            indent = {
              indent_size = 2,
              padding = 1,
            },
            icon = {
              folder_closed = "",
              folder_open = "",
              folder_empty = "ﰊ",
              default = "*",
            },
            git_status = {
              symbols = {
                added = "✚",
                deleted = "✖",
                modified = "",
                renamed = "",
                untracked = "",
                ignored = "",
                unstaged = "",
                staged = "",
                conflict = "",
              }
            },
          },
          window = {
            position = "left",
            width = 40,
            mappings = {
              ["<space>"] = "toggle_node",
              ["<2-LeftMouse>"] = "open",
              ["<cr>"] = "open",
              ["o"] = "open",
              ["S"] = "open_split",
              ["s"] = "open_vsplit",
              ["t"] = "open_tabnew",
              ["C"] = "close_node",
              ["a"] = "add",
              ["A"] = "add_directory",
              ["d"] = "delete",
              ["r"] = "rename",
              ["y"] = "copy_to_clipboard",
              ["x"] = "cut_to_clipboard",
              ["p"] = "paste_from_clipboard",
              ["c"] = "copy",
              ["m"] = "move",
              ["q"] = "close_window",
              ["R"] = "refresh",
            }
          },
          filesystem = {
            filtered_items = {
              visible = false,
              hide_dotfiles = false,
              hide_gitignored = false,
            },
            follow_current_file = {
              enabled = true,
            },
            use_libuv_file_watcher = true,
          },
          git_status = {
            window = {
              position = "float",
              mappings = {
                ["A"] = "git_add_all",
                ["gu"] = "git_unstage_file",
                ["ga"] = "git_add_file",
                ["gr"] = "git_revert_file",
                ["gc"] = "git_commit",
                ["gp"] = "git_push",
                ["gg"] = "git_commit_and_push",
              }
            }
          }
        })
      '';
    };
  };
}
