widget_volume() {
  local volume
  volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null |
      awk '{if ($3 == "[MUTED]") print "MUTED"; else printf "%.0f%%", $2 * 100}')
  volume=${volume:---}
  printf '{"full_text":"VOL %s","color":"%s","separator":false}' "$volume" "$white"
}
