# ~/.config/polybar/scripts/ddc-brightness.sh
#!/usr/bin/env bash
[ -n "${BASH_VERSION:-}" ] || exec /usr/bin/env bash "$0" "$@"
set -Eeuo pipefail

DISPLAY_N="${DDC_DISPLAY:-1}"
STEP_PCT="${STEP:-5}"
SLEEP_MULT="${SLEEP_MULT:-0.4}"
SET_TIMEOUT="${SET_TIMEOUT:-1.5}"

# Nerd Font icons low→high
ICONS="${ICONS:-󰃜;󰃞;󰃟;󰃠}"
IFS=';' read -r -a ICON_ARR <<<"$ICONS"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/polybar-ddc"
mkdir -p "$CACHE_DIR"
STATE="${CACHE_DIR}/disp${DISPLAY_N}.state"  # "cur max"

pick_icon() {
  local pct="$1" n="${#ICON_ARR[@]}"
  (( n == 0 )) && { echo ""; return; }
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  local idx=$(( pct * (n - 1) / 100 ))
  echo "${ICON_ARR[$idx]}"
}

hw_read() {
  local out
  out=$(timeout "$SET_TIMEOUT" ddcutil -d "$DISPLAY_N" \
        --sleep-multiplier "$SLEEP_MULT" getvcp 10 2>/dev/null \
      | awk -F'current value = |, max value = ' '/current value/ {print $2" "$3}')
  [[ -z "$out" ]] && out="0 100"
  echo "$out"
}

ensure_state() {
  if [[ -f "$STATE" ]]; then
    read -r cur max <"$STATE" || true
    [[ -n "${cur:-}" && -n "${max:-}" ]] && return 0
  fi
  hw_read >"$STATE"
}

print_status() {
  ensure_state
  read -r cur max <"$STATE"
  (( max == 0 )) && max=100
  local pct=$(( cur * 100 / max ))
  echo "$(pick_icon "$pct") $pct%"
}

save_state() {
  printf "%s %s\n" "$1" "$2" >"$STATE"
}

apply_hw_async() {
  local new="$1"
  (
    timeout "$SET_TIMEOUT" ddcutil -d "$DISPLAY_N" \
      --sleep-multiplier "$SLEEP_MULT" setvcp --noverify 10 "$new" >/dev/null 2>&1 \
      || timeout "$SET_TIMEOUT" ddcutil -d "$DISPLAY_N" \
           --sleep-multiplier "$SLEEP_MULT" setvcp 10 "$new" >/dev/null 2>&1

    local out
    out=$(timeout "$SET_TIMEOUT" ddcutil -d "$DISPLAY_N" \
            --sleep-multiplier "$SLEEP_MULT" getvcp 10 2>/dev/null \
          | awk -F'current value = |, max value = ' '/current value/ {print $2" "$3}')
    [[ -n "$out" ]] && echo "$out" >"$STATE"

    if [[ -n "${BAR_PID:-}" ]]; then
      polybar-msg -p "$BAR_PID" hook brightness-ddc 0 >/dev/null 2>&1 || true
    fi
  ) & disown
}

set_abs() {
  ensure_state
  read -r cur max <"$STATE"
  (( max == 0 )) && max=100
  local new="$1"
  (( new < 0 ))   && new=0
  (( new > max )) && new=$max
  save_state "$new" "$max"
  apply_hw_async "$new"
  print_status
}

change_pct() {
  local dir="${1:-up}"    # "up" or "down"
  ensure_state
  read -r cur max <"$STATE"
  (( max == 0 )) && max=100
  local delta=$(( STEP_PCT * max / 100 ))
  (( delta == 0 )) && delta=1
  if [[ "$dir" == "down" ]]; then
    set_abs $(( cur - delta ))
  else
    set_abs $(( cur + delta ))
  fi
}

case "${1:-print}" in
  print) print_status ;;
  up)    change_pct up ;;
  down)  change_pct down ;;
  set)   shift; set_abs "${1:-0}" ;;
  sync)  hw_read >"$STATE"; print_status ;;
  *)     print_status ;;
esac
