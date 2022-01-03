#!/bin/sh
xrandr \
    --output eDP --off \
    --output HDMI-A-0 --off \
    --output DisplayPort-0 --mode 3840x2160 --pos 0x0 --rotate normal \
    --output DisplayPort-1 --off \
    --output DisplayPort-2 --mode 1920x1080 --pos 8480x306 --rotate normal \
    --output DisplayPort-3 --primary --mode 2560x1440 --pos 4384x162 --rotate normal \
    --output DisplayPort-4 --off
