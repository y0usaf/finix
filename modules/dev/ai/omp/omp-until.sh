[ $# -ge 2 ] || { echo "usage: omp-until DIR OMP [ARGS...]" >&2; exit 2; }
dir=$1
shift
now=$(date +%s)
until=
for overlay in "$dir"/config.until-*.yml; do
  [ -f "$overlay" ] || continue
  stamp=${overlay##*/config.until-}
  end=$(date -d "${stamp%.yml}" +%s) || { echo "omp-until: $overlay: not a date after config.until-" >&2; exit 2; }
  [ "$end" -gt "$now" ] || continue
  set -- "$@" --config "$overlay"
  if [ -z "$until" ] || [ "$end" -lt "$until" ]; then until=$end; fi
done
export OMP_UNTIL="${until:+${until}000}"
exec "$@"
