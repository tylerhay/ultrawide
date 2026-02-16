#!/usr/bin/env bash

# kill any running bars
pkill -x polybar

# give them a moment to die
sleep 0.5

# launch the “primary” bar on DP-0
polybar --reload main   &

# launch the “secondary” bar on HDMI-1
polybar --reload secondary &
