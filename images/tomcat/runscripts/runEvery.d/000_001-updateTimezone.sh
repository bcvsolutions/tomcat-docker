#!/bin/bash

# Timezone is governed from ENV in a TZ variable,
# some apps are hardcoded to read /etc/timezone or /etc/localtime though.
# Default timezone is UTC, timezone format is expected to be in
# TZDATA database format: https://www.iana.org/time-zones .

# In this case we do not make difference between unset and empty var:
# "-z $VAR" vs. "-z ${VAR+x}"
if [ -z "${TZ}" ]; then
  TZ="UTC";
fi

# sometimes UTC and others are specified as /UTC so we strip the leading slash
TZ=$(echo "$TZ" | sed 's#^/##');

currTZ=$(readlink -f /etc/localtime | sed 's#/usr/share/zoneinfo/##');
if [ "$TZ" == "$currTZ" ]; then
  echo "[$0] Timezone not changed, remains set to $currTZ .";
else
  if [ ! -f "/usr/share/zoneinfo/$TZ" ]; then
    echo "[$0] Zone file "/usr/share/zoneinfo/$TZ" does not exist, preserving existing timezone $currTZ .";
  else
    unlink /etc/localtime && \
    ln -s "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "[$0] Timezone changed from $currTZ to $TZ .";
  fi
fi
