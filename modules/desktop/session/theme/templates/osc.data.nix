{
  generators,
  values,
  ...
}:
generators.shell.render (let
  inherit (generators.shell) sq;
in [
  ["printf" (sq "\\033]10;${values.foreground}\\007")]
  ["printf" (sq "\\033]11;${values.background}\\007")]
  ["printf" (sq "\\033]12;${values.cursor}\\007")]
  ["printf" (sq "\\033]4;0;${values.color0}\\007")]
  ["printf" (sq "\\033]4;1;${values.color1}\\007")]
  ["printf" (sq "\\033]4;2;${values.color2}\\007")]
  ["printf" (sq "\\033]4;3;${values.color3}\\007")]
  ["printf" (sq "\\033]4;4;${values.color4}\\007")]
  ["printf" (sq "\\033]4;5;${values.color5}\\007")]
  ["printf" (sq "\\033]4;6;${values.color6}\\007")]
  ["printf" (sq "\\033]4;7;${values.color7}\\007")]
  ["printf" (sq "\\033]4;8;${values.color8}\\007")]
  ["printf" (sq "\\033]4;9;${values.color9}\\007")]
  ["printf" (sq "\\033]4;10;${values.color10}\\007")]
  ["printf" (sq "\\033]4;11;${values.color11}\\007")]
  ["printf" (sq "\\033]4;12;${values.color12}\\007")]
  ["printf" (sq "\\033]4;13;${values.color13}\\007")]
  ["printf" (sq "\\033]4;14;${values.color14}\\007")]
  ["printf" (sq "\\033]4;15;${values.color15}\\007")]
])
