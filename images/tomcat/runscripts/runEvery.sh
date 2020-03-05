#!/bin/bash

echo "[$0] Last executed on: $(date)" > "$RUNSCRIPTS_PATH/runEvery.done";

echo "[$0] Executing files in order: $(ls $RUNSCRIPTS_PATH/runEvery.d | tr '\n' ' ')";

for f in $(ls "$RUNSCRIPTS_PATH/runEvery.d"); do
  echo "[$0] Executing file $f";
  "$RUNSCRIPTS_PATH/runEvery.d/$f";
done
