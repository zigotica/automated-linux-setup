widget_ram() {
  local total available used pct color=$green
  read -r total available < <(
      awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2}
           END {print total, available}' /proc/meminfo
  )
  used=$(( (total - available) / 1024 ))
  pct=$((100 * (total - available) / total))
  (( pct >= 70 )) && color=$yellow
  (( pct >= 85 )) && color=$red
  printf '{"full_text":"RAM %dM","color":"%s","separator":false}' "$used" "$color"
}
