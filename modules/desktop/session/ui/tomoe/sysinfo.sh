case $1 in
cpu)
  read -r _ user nice system idle iowait irq softirq steal guest guest_nice </proc/stat
  temp=
  for hwmon in /sys/class/hwmon/hwmon*; do
    read -r name <"$hwmon/name" 2>/dev/null || continue
    case $name in
    k10temp) want=Tctl ;;
    coretemp) want='Package id 0' ;;
    zenpower) want=Tdie ;;
    *) continue ;;
    esac
    for label in "$hwmon"/temp*_label; do
      read -r text <"$label" 2>/dev/null && [ "$text" = "$want" ] &&
        read -r temp <"${label%_label}_input" && break 2
    done
    read -r temp <"$hwmon/temp1_input" 2>/dev/null && break
  done
  echo $((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice)) \
    $((idle + iowait)) ${temp:+"$temp"}
  ;;
memory)
  while read -r key value _; do
    case $key in
    MemTotal:) total=$value ;;
    MemAvailable:) available=$value ;;
    esac
  done </proc/meminfo
  echo "$total" "$available"
  ;;
gpu)
  [ "$2" = none ] && exit 1
  if [ "$2" != amd ] && [ -e /proc/driver/nvidia/version ]; then
    out=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
      --format=csv,noheader,nounits) || exit 1
    IFS=', ' read -r util used total temp <<EOF
$out
EOF
    echo "$util" "$used" "$total" "$temp"
    exit
  fi
  [ "$2" = nvidia ] && exit 1
  for card in ${3:+"/sys/class/drm/$3"} /sys/class/drm/card[0-9]; do
    read -r util <"$card/device/gpu_busy_percent" 2>/dev/null || continue
    read -r used <"$card/device/mem_info_vram_used"
    read -r total <"$card/device/mem_info_vram_total"
    temp=
    for input in "$card"/device/hwmon/hwmon*/temp1_input; do
      read -r temp <"$input" 2>/dev/null && temp=$((temp / 1000)) && break
    done
    echo "$util" $((used / 1048576)) $((total / 1048576)) ${temp:+"$temp"}
    exit
  done
  exit 1
  ;;
esac
