#!/usr/bin/env bash

# wmctrl window class we will use
WC="CalcursePopup.CalcursePopup"

# the terminal invocation
# adjust 80x24+100+100 to your preferred size/position
TERMCMD=(
  xfce4-terminal
    --class CalcursePopup
    --geometry 80x24+100+100
    --hide-menubar
    --title CalcursePopup
    --command calcurse
)

# if no calcurse window is up, launch it
if ! wmctrl -lx | grep -q "^.*${WC}"; then
  "${TERMCMD[@]}" &
  # give it a moment to appear
  sleep 0.2
  # float it above all other windows
  wmctrl -x -r ${WC} -b add,above
else
  # if already up, toggle its visibility
  # (hide if visible, show if hidden)
  wmctrl -x -r ${WC} -b toggle,hidden
fi
