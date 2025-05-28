#!/usr/bin/env bash

STAGE_FILE="$(dirname "$0")/stage.json"

if [ ! -f "$STAGE_FILE" ]; then
  echo "{\"stage\": 1}"
else
  cat "$STAGE_FILE"
fi