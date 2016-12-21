#!/bin/sh
# vi: foldmethod=marker
# info {{{1

# DATA #######################################################################
#                                                                            #
#  CurrentCapacity             FullyCharged              MaxCapacity         #
#  CycleCount                  InstantAmperage           AvgTimeToEmpty      #
#  ExternalConnected           IsCharging                Voltage             #
#                                                                            #
##############################################################################

# data getters {{{1

get_connect_from_sys_fs () {
  if [ "$(cat /sys/class/power_supply/A{C,DP1}/online 2>/dev/null)" -eq 1 ]; then
    ExternalConnected=Yes
  else
    ExternalConnected=No
  fi
}
get_data_from_sys_fs () {
  local sys_bat=/sys/class/power_supply/BAT0
  AvgTimeToEmpty=1000000 # TODO
  MaxCapacity=$(cat $sys_bat/charge_full)
  Voltage=$(cat $sys_bat/voltage_now)
  CurrentCapacity=$(cat $sys_bat/charge_now)
  CycleCount=$(cat $sys_bat/cycle_count)
  #FullyCharged=$(cat $sys_bat/)
  #InstantAmperage=$(cat $sys_bat/)
  if [ "$(cat $sys_bat/status)" = Charging ]; then
    IsCharging=Yes
  else
    IsCharging=No
  fi
  #AvgTimeToFull=$(cat $sys_bat/)
  get_connect_from_sys_fs
}

get_data_from_sys_fs_uevent () {
  local data=$(cat /sys/class/power_supply/BAT0/uevent)
  eval $data
  MaxCapacity=$POWER_SUPPLY_CHARGE_FULL
  Voltage=$POWER_SUPPLY_VOLTAGE_NOW
  CurrentCapacity=$POWER_SUPPLY_CHARGE_NOW
  CycleCount=$POWER_SUPPLY_CYCLE_COUNT
  if [ "$POWER_SUPPLY_STATUS" = Charging ]; then
    IsCharging=Yes
  else
    IsCharging=No
  fi
  get_connect_from_sys_fs
  AvgTimeToEmpty=1000000 # TODO
}
get_data_from_sys_fs_uevent_grep () {
  local data=$(grep 'FULL\|NOW\|COUNT\|STATUS' /sys/class/power_supply/BAT0/uevent)
  eval $data
  MaxCapacity=$POWER_SUPPLY_CHARGE_FULL
  Voltage=$POWER_SUPPLY_VOLTAGE_NOW
  CurrentCapacity=$POWER_SUPPLY_CHARGE_NOW
  CycleCount=$POWER_SUPPLY_CYCLE_COUNT
  if [ "$POWER_SUPPLY_STATUS" = Charging ]; then
    IsCharging=Yes
  else
    IsCharging=No
  fi
  get_connect_from_sys_fs
  AvgTimeToEmpty=1000000 # TODO
}
get_data_from_sys_devices () {
:
}

# output functions {{{1

battery_percentage () {
  echo $((100 * CurrentCapacity / MaxCapacity))
}

concice_battery_info () {
  date +"%F %H:%M:%S: ${CurrentCapacity}/${MaxCapacity} mAh, ${CycleCount} cycles"
}

verbose_battery_info () {
  echo "Battery Information:"
  echo
  if [ "$IsCharging" = Yes ]; then
    # TODO:
    echo "  Charging: ${CurrentCapacity}/${MaxCapacity}" \
      "($(battery_percentage)% = ${AvgTimeToFull}min)"
  else
    echo "  Remaining: ${CurrentCapacity}/${MaxCapacity}" \
    "($(battery_percentage)% = ${AvgTimeToEmpty}min)"
  fi
  echo "  Cycles: ${CycleCount}"
  echo "  Fully charged: ${FullyCharged}"
  echo "  Charging: ${IsCharging}"
  #FIXME: display the right amparage
  printf "  Amperage (mA): %s\n" ${InstantAmperage}
  echo "  Voltage (mV): ${Voltage}"
  echo
}

battery_bar () {
  select_utf8_char "$UTF8CHOISE"
  if [ "$IsCharging" = Yes ]; then
    CHAR="$RIGHT"
  else
    CHAR="$LEFT"
  fi
  local fill=$(($(battery_percentage) / 10))
  unset OUT
  i=$fill
  while [ $i -gt 0 ]; do OUT="$OUT$CHAR"; i=$((i - 1)); done
  i=$((10 - fill))
  while [ $i -gt 0 ]; do OUT=" $OUT"; i=$((i - 1)); done
  if [ "$AvgTimeToEmpty" -le 5 ]; then OUT="    ${AvgTimeToEmpty} min "; fi
  if $color; then
    if [ $fill -le 2 ]; then color=red
    elif [ $fill -le 4 ]; then color=yellow
    else color=green
    fi
    if [ "$escape" = bash ]; then
      bash_colors "$fg_bg" "$color"
    elif [ "$escape" = tmux ]; then
      if [ "$fg_bg" = fg ]; then fg_bg=bg; else fg_bg=fg; fi
      tmux_colors "$fg_bg" "$color"
    elif [ "$escape" = zsh ]; then
      zsh_colors "$fg_bg" "$color"
    else
      terminal_colors "$fg_bg" "$color"
    fi
  else
    unset color
  fi
  OUT="[$color$OUT$default]"
  if [ "$ExternalConnected" = Yes ]; then OUT="=$OUT"; fi
  echo "$OUT"
}

battery_bar_for_prompt () {
  select_utf8_char "$UTF8CHOISE"
  if [ "$IsCharging" = Yes ]; then
    CHAR="$RIGHT"
  else
    CHAR="$LEFT"
  fi
  local fill=$(($( battery_percentage) / 10))
  unset OUT
  i=$fill
  while [ $i -gt 0 ]; do OUT="$OUT$CHAR"; i=$((i - 1)); done
  i=$((10 - fill))
  while [ $i -gt 0 ]; do OUT=" $OUT"; i=$((i - 1)); done
  if [ "$AvgTimeToEmpty" -le 5 ]; then OUT="    ${AvgTimeToEmpty} min "; fi
  if $color; then
    if [ $fill -le 2 ]; then color=red
    elif [ $fill -le 4 ]; then color=yellow
    else color=green
    fi
    if [ "$escape" = bash ]; then
      bash_colors "$fg_bg" "$color"
    elif [ "$escape" = tmux ]; then
      if [ "$fg_bg" = fg ]; then fg_bg=bg; else fg_bg=fg; fi
      tmux_colors "$fg_bg" "$color"
    elif [ "$escape" = zsh ]; then
      zsh_colors "$fg_bg" "$color"
    else
      terminal_colors "$fg_bg" "$color"
    fi
  else
    unset color
  fi
  OUT="[$color$OUT$default"
  if [ "$ExternalConnected" = Yes ]; then OUT="=$OUT"; fi
  printf %s "$OUT"
}

# utf8 functions {{{1

select_utf8_char () {
  local length=0
  if $UTF8; then
    case "$UTF8CHOISE" in
      # other
      # 〈 \xe3\x80\x88
      # 〉 \xe3\x80\x89
      # ⎟ \xe2\x8e\x9f
      # ⎸ \xe2\x8e\xb8
      # ⎟ \xe2\x8e\x9f
      # ⎹ \xe2\x8e\xb9
      smallblock)
        # ▮ \xe2\x96\xae
        RIGHT='\xe2\x96\xae'
        LEFT='\xe2\x96\xae'
	fg_bg=fg
	length=3
        ;;
      low)
        # ◣ \xe2\x97\xa3
        RIGHT='\xe2\x97\xa3'
        # ◢ \xe2\x97\xa2
        LEFT='\xe2\x97\xa2'
	fg_bg=fg
	length=3
        ;;
      high)
        # ◤ \xe2\x97\xa4
        RIGHT='\xe2\x97\xa4'
        # ◥ \xe2\x97\xa5
        LEFT='\xe2\x97\xa5'
	fg_bg=fg
	length=3
        ;;
      blank)
	RIGHT=' '
	LEFT=' '
	fg_bg=bg
	length=1
	;;
      block)
	# █ \xe2\x96\x88
        RIGHT='\xe2\x96\x88'
	LEFT="$RIGHT"
	fg_bg=fg
	length=3
	;;
      blitz)
	# ⚡ \xe2\x9a\xa1
	RIGHT='\xe2\x9a\xa1'
	LEFT="$RIGHT"
	fg_bg=fg
	length=3
	;;
      thin)
	# ❯ \xe2\x9d\xaf
	RIGHT='\xe2\x9d\xaf'
	# ❮ \xe2\x9d\xae
	LEFT='\xe2\x9d\xae'
	fg_bg=fg
	length=3
	;;
      fat|*)
	# ▶ \xe2\x96\xb6
	RIGHT='\xe2\x96\xb6'
	# ◀ \xe2\x97\x80
	LEFT='\xe2\x97\x80'
	fg_bg=fg
	length=3
	;;
    esac
  else
    RIGHT='>'
    LEFT='<'
    length=1
  fi
  if [ "${#RIGHT}" -eq $length ] && [ "${#LEFT}" -eq $length ]; then
    : # do nothing
  elif [ "$(printf "$RIGHT" | wc -c)" -eq $length ] && \
     [ "$(printf "$LEFT"  | wc -c)" -eq $length ]; then
    RIGHT=$(printf "$RIGHT")
    LEFT=$(printf "$LEFT")
  fi
}

# color selection functions {{{1
terminal_colors () {
  local start=$(printf '\x1b[')
  local end=m
  local fg_bg=
  default="${start}0${end}"
  if [ "$1" = fg ]; then
    fg_bg=3
  else
    fg_bg=4
  fi
  case "$2" in
    red)
      color="${start}${fg_bg}1${end}"
      ;;
    yellow)
      color="${start}${fg_bg}3${end}"
      ;;
    green)
      color="${start}${fg_bg}2${end}"
      ;;
  esac
}

bash_colors () {
  terminal_colors "$1" "$2"
  color='\['"$color"'\]'
  default='\['"$default"'\]'
}

tmux_colors () {
  color="#[$1=$2]"
  default='#[bg=default,fg=default]'
}

zsh_colors () {
  if [ "$1" = fg ]; then
    color="%F{$2}"
  else
    color="%K{$2}"
  fi
  default="%f%k"
}

select_color () {
  case "$1" in
    red|RED) color="$red";;
    yellow|YELLOW) color="$yellow";;
    green|GREEN) color="$green";;
    default|DEFAULT|*) color="$default";;
  esac
}

# help functions {{{1
usage () {
  local prog=$(basename $0)
  echo "Usage: $prog [ -v ]"
  echo "       $prog -b [ -nc [ -e bash|zsh ] ]"
}
help () {
  echo "Options:"
  echo "  -b  print a bar to indicate battery status"
  echo "  -c  use color (default if stdout is a terminal)"
  echo "  -n  do not use color"
  echo "  -v  be verbose (overriden by -b)"
  echo "  -e  use bash, zsh or tmux escape sequences to be able to display"
  echo "      color output in the shell prompt or status bar"
  echo ""
  echo "The first form prints some info about the battery. The second"
  echo "form prints a grafical representation of the battery fillage"
  echo "which also can be used in shell prompts."
}

# init {{{1

set -e

BAR=false
PROMPT=false
escape=
verbose=false
fg_bg=fg
if [ -t 0 ] && [ -t 1 ]; then color=true; else color=false; fi

# possible utf8 chars for battery graphic
if echo "$LANG" | grep -qi 'utf.\?8'; then
  UTF8=true
else
  UTF8=false
fi

# getopts {{{1
while getopts abce:hnpuU:v FLAG; do
  case $FLAG in
    a) UTF8=false;;
    b) BAR=true verbose=false PROMPT=false;;
    c) color=true;;
    e) escape=$OPTARG color=true;;
    n) color=false escape=;;
    p) PROMPT=true BAR=false verbose=false;;
    u) UTF8=true;;
    U) UTF8=true UTF8CHOISE=$OPTARG;;
    v) verbose=true BAR=false;;
    h) usage; help; exit;;
    *) usage >&2; exit 2;;
  esac
done

# get data {{{1
#if [ ! -e /sys/devices/platform/smapi/BAT0/remaining_percent ]; then
#  get_data_from_sys_devices
if [ -e /sys/class/power_supply/BAT0/uevent ]; then
  get_data_from_sys_fs_uevent_grep
elif [ -e /sys/class/power_supply/BAT0 ]; then
  get_data_from_sys_fs
else
  echo Can not obtain battery data. >&2
  exit 1
fi

# process data {{{1
if $PROMPT; then
  battery_bar_for_prompt
elif $BAR; then
  battery_bar
elif $verbose; then
  verbose_battery_info
else
  concice_battery_info
fi
