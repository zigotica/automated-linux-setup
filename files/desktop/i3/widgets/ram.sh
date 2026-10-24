widget_ram() {
  local total available pct color=$green
  read -r total available < <(
      awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2}
           END {print total, available}' /proc/meminfo
  )
  pct=$((100 * (total - available) / total))
  (( pct >= 70 )) && color=$yellow
  (( pct >= 85 )) && color=$red
  printf '{"full_text":"RAM %d%%","color":"%s","separator":false}' "$pct" "$color"
}
