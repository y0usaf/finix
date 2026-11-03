{
  generators,
  values,
  filters,
  ...
}:
generators.iniSource [
  {
    name = "colors-dark";
    groups = [[["foreground" "${filters.strip values.foreground}"] ["background" "${filters.strip values.background}"] ["selection-foreground" "${filters.strip values.background}"] ["selection-background" "${filters.strip values.foreground}"] ["urls" "${filters.strip values.color6}"]] [["regular0" "${filters.strip values.color0}"] ["regular1" "${filters.strip values.color1}"] ["regular2" "${filters.strip values.color2}"] ["regular3" "${filters.strip values.color3}"] ["regular4" "${filters.strip values.color4}"] ["regular5" "${filters.strip values.color5}"] ["regular6" "${filters.strip values.color6}"] ["regular7" "${filters.strip values.color7}"]] [["bright0" "${filters.strip values.color8}"] ["bright1" "${filters.strip values.color9}"] ["bright2" "${filters.strip values.color10}"] ["bright3" "${filters.strip values.color11}"] ["bright4" "${filters.strip values.color12}"] ["bright5" "${filters.strip values.color13}"] ["bright6" "${filters.strip values.color14}"] ["bright7" "${filters.strip values.color15}"]]];
  }
]
