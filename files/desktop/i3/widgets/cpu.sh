# CPU utilization between refreshes. State stays in the coordinator shell.
read_cpu() {
  local cpu user nice system idle iowait irq softirq steal rest
  read -r cpu user nice system idle iowait irq softirq steal rest < /proc/stat
  CPU_IDLE=$((idle + iowait))
  CPU_TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
}

cpu_init() {
  read_cpu
  prev_idle=$CPU_IDLE
  prev_total=$CPU_TOTAL
}

widget_cpu() {
  read_cpu
  local delta_total=$((CPU_TOTAL - prev_total))
  local delta_idle=$((CPU_IDLE - prev_idle))
  local pct=0 color=$green
  if (( delta_total > 0 )); then
      pct=$((100 * (delta_total - delta_idle) / delta_total))
  fi
  prev_idle=$CPU_IDLE
  prev_total=$CPU_TOTAL
  (( pct >= 60 )) && color=$yellow
  (( pct >= 85 )) && color=$red
  printf '{"full_text":"CPU %d%%","color":"%s","separator":false}' "$pct" "$color"
}
