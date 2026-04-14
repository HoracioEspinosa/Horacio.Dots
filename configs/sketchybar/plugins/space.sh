#!/bin/bash

# Space/Workspace indicator script
# Only shows: active space + spaces with windows

ACCENT=0xffe0c15a
WHITE=0xfff3f6f9
DIM=0xff565f89
ISLAND_BG=0xff121620
ISLAND_BORDER=0xff263356

ANIM_DURATION=4
ANIM_CURVE="tanh"

SPACE_ID=${NAME#space.}

# Get apps in this space
APPS=$(yabai -m query --windows --space $SPACE_ID 2>/dev/null | jq -r '.[].app' 2>/dev/null | sort -u | head -3 | paste -sd '|' - | sed 's/|/ | /g')

# Only show the active/selected space
if [ "$SELECTED" != "true" ]; then
  sketchybar --set $NAME drawing=off
  exit 0
fi

sketchybar --set $NAME drawing=on

if [ -n "$APPS" ]; then
  LABEL="$SPACE_ID · $APPS"
else
  LABEL="$SPACE_ID"
fi

sketchybar --animate $ANIM_CURVE $ANIM_DURATION --set $NAME \
  label="$LABEL" \
  label.color=$ACCENT \
  label.font="IosevkaTerm NF:Bold:12.0" \
  background.border_color=$ACCENT
