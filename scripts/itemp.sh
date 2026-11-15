#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=helpers.sh
source "$CURRENT_DIR/helpers.sh"

print_cpu_temp() {
  if command_exists "sensors"; then
    local units=$1
    local temp
    temp=$(sensors | awk '
      /^Package id 0:/ { gsub(/[^0-9.]/, "", $4); print $4; exit }
      /^(Tctl|Tdie):/ { gsub(/[^0-9.]/, "", $2); print $2; exit }
    ')
    if [ -z "$temp" ]; then
      echo ""
      return
    fi
    if [ "$units" = "F" ]; then
      temp=$(celsius_to_fahrenheit "$temp")
    fi
    printf "I:%3.0fº%s" "$temp" "$units"
  else
    echo ""
  fi
}

main() {
  local units
  units=$(get_tmux_option "@temp_units" "C")
  print_cpu_temp "$units"
}
main
