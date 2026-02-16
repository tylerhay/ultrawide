#!/usr/bin/env bash

# Controller MAC
MAC="98:B6:EA:F9:12:38"

# You must have 'bluetoothctl' output in English for regex to work
CONNECTED=$(bluetoothctl info "$MAC" | grep "Connected: yes")

if [[ "$1" == "toggle" ]]; then
  bluetoothctl connect "$MAC"
  exit
fi

if [[ -n "$CONNECTED" ]]; then
  # Connected icon
  echo "󰖺"    # (Use secondary font if needed for icons)
else
  # Disconnected icon
  echo "󰖻"
fi
