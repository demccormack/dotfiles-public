#!/bin/bash

# MacOS battery saving script
# This doesn't run unless you set up a cron job for it


set -euo pipefail
[[ "$(uname)" == Darwin ]] || false

DANGER=30
WARNING=35

PERCENT=$(pmset -g batt | grep -oE '[0-9]+%' | sed 's/%//g')
DISCHARGING=$(pmset -g batt | grep -o discharging) || true

[[ "$DISCHARGING" ]] || false

if [[ "$PERCENT" -le "$DANGER" ]]
then
    shutdown -s now
fi

if [[ "$PERCENT" -le "$WARNING" ]]
then
    wall <<-EOF
        Battery level ${PERCENT}%

        Please plug in to AC power!
        Computer will sleep at ${DANGER}%
EOF
fi

