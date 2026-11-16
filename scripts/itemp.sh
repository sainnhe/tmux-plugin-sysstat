#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=helpers.sh
source "$CURRENT_DIR/helpers.sh"

get_cpu_temp() {
  if is_osx; then
    get_macmon_temp "cpu_temp_avg"
    return
  fi

  command_exists "sensors" || return 0

  sensors | awk '
    /^Package id 0:/ { gsub(/[^0-9.]/, "", $4); print $4; exit }
    /^(Tctl|Tdie):/ { gsub(/[^0-9.]/, "", $2); print $2; exit }
  '
}

print_cpu_temp() {
  local units=$1
  local temp

  temp=$(get_cpu_temp)
  if [ -z "$temp" ]; then
    echo ""
    return
  fi

  if [ "$units" = "F" ]; then
    temp=$(celsius_to_fahrenheit "$temp")
  fi

  printf "C:%3.0fº%s" "$temp" "$units"
}

main() {
  local units
  units=$(get_tmux_option "@temp_units" "C")
  print_cpu_temp "$units"
}
main
