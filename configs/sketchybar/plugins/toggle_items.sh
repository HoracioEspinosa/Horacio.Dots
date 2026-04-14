#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    SKETCHYBAR ITEM TOGGLE (fzf interactive)                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Usage: toggle_items.sh
# Interactive loop: select items to toggle, Esc to exit.

STATE_FILE="$HOME/.config/sketchybar/toggle_state"
mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"

get_menubar_state() {
  local hidden
  hidden=$(/usr/bin/defaults read NSGlobalDomain _HIHideMenuBar 2>/dev/null)
  if [ "$hidden" = "1" ]; then
    echo "OFF"
  else
    echo "ON"
  fi
}

toggle_menubar() {
  local state="$1"
  if [ "$state" = "[ON]" ]; then
    /usr/bin/defaults write NSGlobalDomain _HIHideMenuBar -bool true
    yabai -m config menubar_opacity 0.0
  else
    /usr/bin/defaults write NSGlobalDomain _HIHideMenuBar -bool false
    yabai -m config menubar_opacity 1.0
  fi
  killall Dock 2>/dev/null || true
}

build_list() {
  local list=""

  # Special toggle: native macOS menu bar
  local mb_state
  mb_state=$(get_menubar_state)
  list+="[$mb_state]  Native-Menu-Bar"$'\n'

  for ITEM in $(sketchybar --query bar | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data.get('items', []):
    print(item)
" 2>/dev/null); do
    DRAWING=$(sketchybar --query "$ITEM" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
geo = data.get('geometry', {})
print('ON' if geo.get('drawing', 'on') == 'on' else 'OFF')
" 2>/dev/null)
    DRAWING=${DRAWING:-ON}
    list+="[$DRAWING]  $ITEM"$'\n'
  done
  echo "$list"
}

toggle_item() {
  local state="$1"
  local item="$2"

  if [ "$state" = "[ON]" ]; then
    sketchybar --set "$item" drawing=off
    grep -qxF "$item" "$STATE_FILE" 2>/dev/null || echo "$item" >> "$STATE_FILE"
  else
    sketchybar --set "$item" drawing=on
    grep -vxF "$item" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
}

while true; do
  LIST=$(build_list)

  if [ -z "$LIST" ]; then
    echo "No items found"
    exit 1
  fi

  SELECTED=$(echo "$LIST" | fzf \
    --multi \
    --header="Tab=multi  Enter=toggle  Esc=exit" \
    --prompt="SketchyBar > " \
    --preview="sketchybar --query {2} 2>/dev/null | python3 -m json.tool 2>/dev/null || echo 'No info'" \
    --preview-window=right:40%:wrap \
    --color="bg+:#263356,fg+:#f3f6f9,hl:#e0c15a,hl+:#ffe066,pointer:#ff8dd7,marker:#b7cc85,header:#7fb4ca")

  # Esc or empty = exit
  if [ -z "$SELECTED" ]; then
    break
  fi

  echo "$SELECTED" | while IFS= read -r LINE; do
    STATE=$(echo "$LINE" | awk '{print $1}')
    ITEM=$(echo "$LINE" | awk '{print $2}')
    if [ "$ITEM" = "Native-Menu-Bar" ]; then
      toggle_menubar "$STATE"
    else
      toggle_item "$STATE" "$ITEM"
    fi
  done
done
