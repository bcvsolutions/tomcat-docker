#!/bin/bash

_term() {
  echo "[$0] Caught SIGTERM signal, killing everything that runs under tomcat...";
  killall -u tomcat -w;
}

trap _term SIGTERM

readonly RUNSCRIPTS_PATH

# If you need to do something extra special, you can script it yourself.
# Files are taken from run.d/ in alphabetical order and SOURCED into this bash.
# Sourcing allows you to operate one the whole env if you need.
# This is invoked every time the container starts.
echo "[$0] Sourcing files in order: $(ls $RUNSCRIPTS_PATH/run.d | tr '\n' ' ')";
for f in $(ls "$RUNSCRIPTS_PATH/run.d"); do
  echo "[$0] Sourcing file $f";
  . "$RUNSCRIPTS_PATH/run.d/$f";
done

if [ -z ${STOP_TIMEOUT+x} ]; then
  STOP_TIMEOUT=15;
fi
echo "[$0] Tomcat STOP_TIMEOUT set to $STOP_TIMEOUT";

if [ ! -z ${RUNONCE_BREAKPOINT+x} ]; then
  echo "[$0] RUNONCE_BREAKPOINT. SLEEPING 3600.";
  sleep 3600;
fi
echo "[$0] runOnce.sh...";
$RUNSCRIPTS_PATH/runOnce.sh;

if [ ! -z ${RUNEVERY_BREAKPOINT+x} ]; then
  echo "[$0] RUNEVERY_BREAKPOINT. SLEEPING 3600.";
  sleep 3600;
fi
echo "[$0] runEvery.sh...";
$RUNSCRIPTS_PATH/runEvery.sh;

if [ ! -z ${STARTTOMCAT_BREAKPOINT+x} ]; then
  echo "[$0] STARTTOMCAT_BREAKPOINT. SLEEPING 3600.";
  sleep 3600;
fi
echo "[$0] startTomcat.sh...";
$RUNSCRIPTS_PATH/startTomcat.sh &
child=$!

# wait for tomcat exit
wait "$child"
echo "[$0] Starting to wait (in a loop) for tomcat to terminate.";
# when exiting, wait at most STOP_TIMEOUT seconds
for i in {1.."$STOP_TIMEOUT"}; do
  tcatprocs=$(ps -ef | grep -c ^tomcat);
  if [ "$tcatprocs" -eq 0 ]; then
    break;
  fi
  sleep 1;
  echo "[$0] Loop waited.";
done
# safety to get other processes in proctree chance to terminate
echo "[$0] Safety sleep 1 second before terminating the container.";
sleep 1
