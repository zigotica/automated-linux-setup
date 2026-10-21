#!/bin/bash

green='#98c379'
yellow='#e5c07b'
red='#e06c75'
white='#dddddd'
gray='#888888'

widget_dir="$(dirname -- "${BASH_SOURCE[0]}")/widgets"
widgets=(cpu ram disk wifi volume clock)
for widget in "${widgets[@]}"; do
    source "$widget_dir/$widget.sh" || exit 1
done

cpu_init
printf '{"version":1}\n[\n'

while true; do
    sleep 2
    printf '['
    separator=''
    for widget in "${widgets[@]}"; do
        printf '%s' "$separator"
        "widget_$widget"
        separator=',{"full_text":"|","color":"'"$gray"'","separator":false},'
    done
    printf '],\n'
done
