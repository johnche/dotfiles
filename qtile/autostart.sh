#!/usr/bin/env sh

# set correct resolution
xrandr -s 5120x1440

# wallpaper
nitrogen --restore &

# notification
dunst &
