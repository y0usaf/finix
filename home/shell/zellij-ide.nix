###############################################################################
# Zellij IDE Layout Module
# Provides the IDE layout configuration for Zellij
# - Neovim editor pane
# - Claude terminal pane
# - Lazygit pane for version control
###############################################################################
{lib, ...}: {
  ###########################################################################
  # IDE Layout Configuration
  ###########################################################################
  home.shell.zellij.layouts.ide = ''
    layout {
        cwd "/home/y0usaf"
        tab name="Tab #1" focus=true hide_floating_panes=true {
            pane split_direction="vertical" {
                pane size="25%" command="bash" {
                    args "-c" "while true; do echo 'File browser pane - implement file browser here'; sleep 60; done"
                }
                pane command="/nix/store/10niqvrkxcxv7m9svqg9sw03pq2f9c79-neovim-unwrapped-0.11.1/bin/nvim" size="50%" {
                    args "--cmd" "lua" "vim.g.loaded_node_provider=0;vim.g.loaded_perl_provider=0;vim.g.loaded_python_provider=0;vim.g.python3_host_prog='/nix/store/nw09bl4zh8ydf2h32qrxrp22b619v2m2-neovim-0.11.1/bin/nvim-python3';vim.g.ruby_host_prog='/nix/store/nw09bl4zh8ydf2h32qrxrp22b619v2m2-neovim-0.11.1/bin/nvim-ruby'" "--cmd" "set" "packpath^=/nix/store/vil1bkzh8fyccnkg30anpvzv0m79fdhj-vim-pack-dir" "--cmd" "set" "rtp^=/nix/store/vil1bkzh8fyccnkg30anpvzv0m79fdhj-vim-pack-dir"
                }
                pane size="50%" {
                    pane command="claude" cwd="nixos" focus=true size="50%"
                    pane command="/nix/store/0jr78nw5jw3paq9fhgvcldi2bva98wjq-lazygit-0.53.0/bin/lazygit" cwd="nixos" size="50%"
                }
            }
        }
        new_tab_template {
            pane
        }
    }
  '';

  ###########################################################################
  # IDE Shell Integration
  ###########################################################################
  users.users.y0usaf.maid.file.home.".config/zsh/.zshrc".text = lib.mkAfter ''
    # ----------------------------
    # IDE Alias
    # ----------------------------
    alias ide='zellij --layout ~/.config/zellij/layouts/ide.kdl'
  '';
}
