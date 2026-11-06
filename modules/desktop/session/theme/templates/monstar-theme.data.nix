{
  generators,
  values,
  filters,
  ...
}:
generators.keyValueSource [[["foreground" "${filters.strip values.foreground}"] ["background" "${filters.strip values.background}"] ["cursor-color" "${filters.strip values.foreground}"] ["cursor-text" "${filters.strip values.background}"] ["selection-foreground" "${filters.strip values.background}"] ["selection-background" "${filters.strip values.foreground}"]] [["palette" "0=${filters.strip values.color0}"] ["palette" "1=${filters.strip values.color1}"] ["palette" "2=${filters.strip values.color2}"] ["palette" "3=${filters.strip values.color3}"] ["palette" "4=${filters.strip values.color4}"] ["palette" "5=${filters.strip values.color5}"] ["palette" "6=${filters.strip values.color6}"] ["palette" "7=${filters.strip values.color7}"] ["palette" "8=${filters.strip values.color8}"] ["palette" "9=${filters.strip values.color9}"] ["palette" "10=${filters.strip values.color10}"] ["palette" "11=${filters.strip values.color11}"] ["palette" "12=${filters.strip values.color12}"] ["palette" "13=${filters.strip values.color13}"] ["palette" "14=${filters.strip values.color14}"] ["palette" "15=${filters.strip values.color15}"]]]
