#!/bin/bash

# Power button click handler - shows confirmation dialog before shutdown
RESPONSE=$(osascript -e 'display dialog "¿Apagar la computadora?" buttons {"Cancelar", "Apagar"} default button "Cancelar" cancel button "Cancelar" with title "Power Off" with icon caution' 2>/dev/null)

if echo "$RESPONSE" | grep -q "Apagar"; then
  osascript -e 'tell application "loginwindow" to «event aevtrsdn»'
fi
