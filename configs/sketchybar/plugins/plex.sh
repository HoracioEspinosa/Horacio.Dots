#!/bin/bash

# PLEX - displays server status and active stream count

GREEN=0xffb7cc85
ORANGE=0xfffff7b1
DIM=0xff565f89

TOKEN_FILE="$HOME/.config/sketchybar/plex_token"

# Read token from file
if [ ! -f "$TOKEN_FILE" ]; then
  sketchybar --set $NAME icon.color=$DIM label="--"
  exit 0
fi

PLEX_TOKEN=$(cat "$TOKEN_FILE")

# Check if Plex Media Server is running
if ! pgrep -f "Plex Media Server" > /dev/null 2>&1; then
  sketchybar --set $NAME icon.color=$DIM label="OFF"
  exit 0
fi

# Query active sessions
SESSIONS=$(curl -s --max-time 3 "http://localhost:32400/status/sessions?X-Plex-Token=$PLEX_TOKEN" 2>/dev/null)

if [ -z "$SESSIONS" ]; then
  sketchybar --set $NAME icon.color=$GREEN label="0"
  exit 0
fi

COUNT=$(echo "$SESSIONS" | grep -o 'size="[0-9]*"' | head -1 | grep -o '[0-9]*')
COUNT=${COUNT:-0}

if [ "$COUNT" -gt 0 ]; then
  COLOR=$ORANGE
  LABEL="${COUNT} 󰐊"
else
  COLOR=$GREEN
  LABEL="0"
fi

sketchybar --set $NAME icon.color="$COLOR" label="$LABEL"
