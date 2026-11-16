#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=helpers.sh
source "$CURRENT_DIR/helpers.sh"

itemp_view_tmpl=$(get_tmux_option "@sysstat_itemp_view_tmpl" 'C:#[fg=#{itemp.color}]#{itemp.temp}º#{itemp.units}#[default]')

# thresholds are always in Celsius, regardless of @temp_units
itemp_medium_threshold=$(get_tmux_option "@sysstat_itemp_medium_threshold" "60")
itemp_stress_threshold=$(get_tmux_option "@sysstat_itemp_stress_threshold" "80")

itemp_color_low=$(get_tmux_option "@sysstat_itemp_color_low" "green")
itemp_color_medium=$(get_tmux_option "@sysstat_itemp_color_medium" "yellow")
itemp_color_stress=$(get_tmux_option "@sysstat_itemp_color_stress" "red")

get_itemp_color() {
  local temp=$1

  if fcomp "$itemp_stress_threshold" "$temp"; then
    echo "$itemp_color_stress";
  elif fcomp "$itemp_medium_threshold" "$temp"; then
    echo "$itemp_color_medium";
  else
    echo "$itemp_color_low";
  fi
}

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
  local temp_color
  local itemp_view

  temp=$(get_cpu_temp)
  if [ -z "$temp" ]; then
    echo ""
    return
  fi

  temp_color=$(get_itemp_color "$temp")

  if [ "$units" = "F" ]; then
    temp=$(celsius_to_fahrenheit "$temp")
  fi

  itemp_view="$itemp_view_tmpl"
  itemp_view="${itemp_view//'#{itemp.temp}'/$(printf "%3.0f" "$temp")}"
  itemp_view="${itemp_view//'#{itemp.units}'/$units}"
  itemp_view="${itemp_view//'#{itemp.color}'/$(echo "$temp_color" | awk '{ print $1 }')}"
  itemp_view="${itemp_view//'#{itemp.color2}'/$(echo "$temp_color" | awk '{ print $2 }')}"
  itemp_view="${itemp_view//'#{itemp.color3}'/$(echo "$temp_color" | awk '{ print $3 }')}"

  echo "$itemp_view"
}

main() {
  local units
  units=$(get_tmux_option "@temp_units" "C")
  print_cpu_temp "$units"
}
main
