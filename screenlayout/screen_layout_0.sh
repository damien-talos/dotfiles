#!/bin/sh
xrandr \
    --output eDP --off \
    --output HDMI-A-0 --off \
    --output DisplayPort-0 --off \
    --output DisplayPort-1 --off \
    --output DisplayPort-2 --mode 1920x1080 --pos 3840x0 --rotate normal \
    --output DisplayPort-3 --primary --mode 2560x1440 --pos 7680x720 --rotate normal \
    --output DisplayPort-4 --mode 3840x2160 --pos 0x0 --rotate normal
