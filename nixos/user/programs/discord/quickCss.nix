{
  config,
  lib,
  ...
}: {
  # QuickCSS is now managed by wallust templates
  # See: lib/appearance/wallust/templates.nix (discordQuickCss)
  # Wallust outputs to:
  #   ~/.config/Vencord/settings/quickCss.css
  #   ~/.config/vesktop/settings/quickCss.css
  #
  # Run `wt cs <theme>` or `wt theme <name>` to regenerate
  config = {};
}
