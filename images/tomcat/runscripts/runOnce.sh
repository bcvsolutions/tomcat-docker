#!/bin/bash

if [ -f "$RUNSCRIPTS_PATH/runOnce.done" ]; then
    echo "[$0] Already executed once. Exiting.";
    exit;
fi

echo "[$0] Executed on: $(date)" > "$RUNSCRIPTS_PATH/runOnce.done";

echo "[$0] Executing files in order: $(ls $RUNSCRIPTS_PATH/runOnce.d | tr '\n' ' ')";

for f in $(ls "$RUNSCRIPTS_PATH/runOnce.d"); do
  echo "[$0] Executing file $f";
  "$RUNSCRIPTS_PATH/runOnce.d/$f";
done
