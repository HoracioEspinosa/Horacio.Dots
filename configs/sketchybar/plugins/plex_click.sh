#!/bin/bash

# PLEX CLICK - left click opens web, right click refreshes all libraries

TOKEN_FILE="$HOME/.config/sketchybar/plex_token"
ACCENT=0xffe0c15a
GREEN=0xffb7cc85

if [ "$BUTTON" = "right" ]; then
  if [ ! -f "$TOKEN_FILE" ]; then
    exit 0
  fi

  PLEX_TOKEN=$(cat "$TOKEN_FILE")

  # Visual feedback: scanning
  sketchybar --set $NAME icon.color=$ACCENT label="SCAN"

  # Get all library section IDs and refresh each one
  SECTIONS=$(curl -s --max-time 3 "http://localhost:32400/library/sections?X-Plex-Token=$PLEX_TOKEN" 2>/dev/null \
    | grep -o 'key="[0-9]*"' | grep -o '[0-9]*')

  for SECTION_ID in $SECTIONS; do
    curl -s --max-time 5 -X GET \
      "http://localhost:32400/library/sections/$SECTION_ID/refresh?X-Plex-Token=$PLEX_TOKEN" \
      > /dev/null 2>&1
  done

  # Visual feedback: done
  sketchybar --set $NAME icon.color=$GREEN label="OK"
  sleep 1
  # Trigger normal update
  sketchybar --trigger plex_refresh
else
  open "http://localhost:32400/web"
fi
