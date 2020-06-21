#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=helpers.sh
source "$CURRENT_DIR/helpers.sh"

print_gpu_temp() {
  if command_exists "sensors"; then
    local units=$1
    local temp
    temp=$(nvidia-smi -q --display=TEMPERATURE | grep 'GPU Current' | grep -Eo "[[:digit:]]+")
    if [ "$units" = "F" ]; then
      temp=$(celsius_to_fahrenheit "$temp")
    fi
    printf "N:%3.0fº%s" "$temp" "$units"
  else
    echo "no sensors found"
  fi
}

main() {
  local units
  units=$(get_tmux_option "@temp_units" "C")
  print_gpu_temp "$units"
}
main
