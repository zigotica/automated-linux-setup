temperature_critical_is_valid() {
  (( $1 > 0 ))
}

widget_temp() {
  local hw zone input trip_type sensor_crit sensor_crit_value hottest=0 critical=0 color=$green

  for hw in /sys/class/hwmon/hwmon*; do
    [[ -r $hw/name ]] || continue
    [[ $(<"$hw/name") == coretemp ]] || continue

    for input in "$hw"/temp*_input; do
      [[ -r $input ]] || continue
      (( $(<"$input") > hottest )) && hottest=$(<"$input")

      sensor_crit=${input%_input}_crit
      if [[ -r $sensor_crit ]]; then
        sensor_crit_value=$(<"$sensor_crit")
        if temperature_critical_is_valid "$sensor_crit_value" && (( critical == 0 || sensor_crit_value < critical )); then
          critical=$sensor_crit_value
        fi
      fi
    done
  done

  # ACPI zones may trigger firmware shutdown before the CPU core sensor does.
  for zone in /sys/class/thermal/thermal_zone*; do
    input=$zone/temp
    [[ -r $input ]] || continue
    (( $(<"$input") > hottest )) && hottest=$(<"$input")

    for trip_type in "$zone"/trip_point_*_type; do
      [[ -r $trip_type ]] || continue
      [[ $(<"$trip_type") == critical ]] || continue
      sensor_crit=${trip_type%_type}_temp
      if [[ -r $sensor_crit ]]; then
        sensor_crit_value=$(<"$sensor_crit")
        if temperature_critical_is_valid "$sensor_crit_value" && (( critical == 0 || sensor_crit_value < critical )); then
          critical=$sensor_crit_value
        fi
      fi
    done
  done

  if (( hottest == 0 )); then
    printf '{"full_text":"TEMP --","color":"%s","separator":false}' "$gray"
    return
  fi

  (( critical == 0 )) && critical=90000
  (( hottest >= critical - 15000 )) && color=$yellow
  (( hottest >= critical - 5000 )) && color=$red
  printf '{"full_text":"TEMP %d°C","color":"%s","separator":false}' \
    "$(((hottest + 500) / 1000))" "$color"
}
