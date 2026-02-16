#!/usr/bin/env bash
#
# ~/.config/polybar/scripts/powermenu.sh
#
# Requires: rofi (or replace with dmenu)  
# Make sure this file is executable: chmod +x ~/.config/polybar/scripts/powermenu.sh

# The menu entries
options="Lock\nSuspend\nReboot\nShutdown\nLogout"
  
# Show the menu
chosen="$(echo -e "$options" \
    | rofi -dmenu -i -p "⏻ Power")"

# Act on the choice
case "$chosen" in
    Lock)
		i3lock-fancy
		;;
    Suspend)
        # optional: lock screen here, e.g. i3lock
        systemctl suspend
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    Logout)
        # This is a generic logout—kills your session
        loginctl terminate-session "$XDG_SESSION_ID"
        ;;
    *)
        # nothing or Cancel
        ;;
esac
