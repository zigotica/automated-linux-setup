widget_disk() {
  local pct color=$green
  pct=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
  (( pct >= 70 )) && color=$yellow
  (( pct >= 85 )) && color=$red
  printf '{"full_text":"DISK %s%%","color":"%s","separator":false}' "$pct" "$color"
}
