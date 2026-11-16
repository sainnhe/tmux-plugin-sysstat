#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=helpers.sh
source "$CURRENT_DIR/helpers.sh"

ntemp_view_tmpl=$(get_tmux_option "@sysstat_ntemp_view_tmpl" 'G:#[fg=#{ntemp.color}]#{ntemp.temp}º#{ntemp.units}#[default]')

# thresholds are always in Celsius, regardless of @temp_units
ntemp_medium_threshold=$(get_tmux_option "@sysstat_ntemp_medium_threshold" "60")
ntemp_stress_threshold=$(get_tmux_option "@sysstat_ntemp_stress_threshold" "80")

ntemp_color_low=$(get_tmux_option "@sysstat_ntemp_color_low" "green")
ntemp_color_medium=$(get_tmux_option "@sysstat_ntemp_color_medium" "yellow")
ntemp_color_stress=$(get_tmux_option "@sysstat_ntemp_color_stress" "red")

get_ntemp_color() {
  local temp=$1

  if fcomp "$ntemp_stress_threshold" "$temp"; then
    echo "$ntemp_color_stress";
  elif fcomp "$ntemp_medium_threshold" "$temp"; then
    echo "$ntemp_color_medium";
  else
    echo "$ntemp_color_low";
  fi
}

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
  local temp_color
  local ntemp_view

  if is_osx; then
    temp=$(get_macmon_temp "gpu_temp_avg")
  else
    temp=$(get_nvidia_temp)
    if [ -z "$temp" ]; then
      temp=$(get_amd_temp)
    fi
  fi

  if [ -z "$temp" ]; then
    echo ""
    return
  fi

  temp_color=$(get_ntemp_color "$temp")

  if [ "$units" = "F" ]; then
    temp=$(celsius_to_fahrenheit "$temp")
  fi

  ntemp_view="$ntemp_view_tmpl"
  ntemp_view="${ntemp_view//'#{ntemp.temp}'/$(printf "%3.0f" "$temp")}"
  ntemp_view="${ntemp_view//'#{ntemp.units}'/$units}"
  ntemp_view="${ntemp_view//'#{ntemp.color}'/$(echo "$temp_color" | awk '{ print $1 }')}"
  ntemp_view="${ntemp_view//'#{ntemp.color2}'/$(echo "$temp_color" | awk '{ print $2 }')}"
  ntemp_view="${ntemp_view//'#{ntemp.color3}'/$(echo "$temp_color" | awk '{ print $3 }')}"

  echo "$ntemp_view"
}

main() {
  local units
  units=$(get_tmux_option "@temp_units" "C")
  print_gpu_temp "$units"
}
main
