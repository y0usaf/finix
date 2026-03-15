# NixOS-specific aliases for Nushell
_: ''
  # Android development (env var override - must be def)
  def adb [...args: string] { with-env { HOME: $"($env.XDG_DATA_HOME)/android" } { ^adb ...$args } }

  # Music on console
  def mocp [...args: string] { ^mocp -M $"($env.XDG_CONFIG_HOME)/moc" -O $"MOCDir=($env.XDG_CONFIG_HOME)/moc" ...$args }

  # Yarn XDG compliance
  def yarn [...args: string] { ^yarn --use-yarnrc $"($env.XDG_CONFIG_HOME)/yarn/config" ...$args }

  # Nix store queries (uses pipes - must be def)
  def pkgs [query: string] {
    ^nix-store --query --requisites /run/current-system | lines | each { |l| $l | str replace -r '^[^-]*-' '''' } | sort | uniq | where $it =~ $query
  }

  def pkgcount [] {
    ^nix-store --query --requisites /run/current-system | lines | each { |l| $l | str replace -r '^[^-]*-' '''' } | sort | uniq | length
  }
''
