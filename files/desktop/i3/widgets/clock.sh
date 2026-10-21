widget_clock() {
  printf '{"full_text":"%s","color":"%s","min_width":35,"align":"left","separator":false}' \
  "$(date '+%H:%M')" "$white"
}
