#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=helpers.sh
source "$CURRENT_DIR/helpers.sh"

get_nvidia_temp() {
  if ! command_exists "nvidia-smi"; then
    return
  fi
  nvidia-smi -q --display=TEMPERATURE | grep -m 1 'GPU Current Temp' | grep -Eo "[[:digit:]]+" | head -n 1
}

get_amd_temp() {
  if ! command_exists "sensors"; then
    return
  fi
  sensors | awk '
    /^amdgpu-/ { amd = 1 }
    amd && /^edge:/ { gsub(/[^0-9.]/, "", $2); print $2; exit }
  '
}

print_gpu_temp() {
  local units=$1
  local temp
  temp=$(get_nvidia_temp)
  if [ -z "$temp" ]; then
    temp=$(get_amd_temp)
  fi
  if [ -z "$temp" ]; then
    echo ""
    return
  fi
  if [ "$units" = "F" ]; then
    temp=$(celsius_to_fahrenheit "$temp")
  fi
  printf "G:%3.0fº%s" "$temp" "$units"
}

main() {
  local units
  units=$(get_tmux_option "@temp_units" "C")
  print_gpu_temp "$units"
}
main
