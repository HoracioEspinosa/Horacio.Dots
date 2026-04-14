#!/bin/bash

# DOCKER - displays Docker Desktop status (icon only)

GREEN=0xffb7cc85
DIM=0xff565f89

if docker info > /dev/null 2>&1; then
  sketchybar --set $NAME icon.color=$GREEN
else
  sketchybar --set $NAME icon.color=$DIM
fi
