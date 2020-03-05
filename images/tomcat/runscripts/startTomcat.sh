#!/bin/bash

# Those are defaults if not set from outside. Defaults on empty string.
if [ -z "${JAVA_XMS}" ]; then
  JAVA_XMS="512M";
fi
if [ -z "${JAVA_XMX}" ]; then
  JAVA_XMX="1024M";
fi
JAVA_HOME="/usr/lib/jvm/java-openjdk";
CATALINA_PID="/opt/tomcat/current/temp/tomcat.pid";
CATALINA_HOME="/opt/tomcat/current";
CATALINA_BASE="/opt/tomcat/current";
CATALINA_OPTS="-Xms${JAVA_XMS} -Xmx${JAVA_XMX} -server -XX:+UseParallelGC";
JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Djavax.servlet.request.encoding=UTF-8";

# *_ADD variables are the way to customize JAVA_OPTS and CATALINA_OPTS.
# Empty-string variables are treated as if they did not exist.
if [ ! -z "${CATALINA_OPTS_ADD}" ]; then
  CATALINA_OPTS="$CATALINA_OPTS $CATALINA_OPTS_ADD";
fi
if [ ! -z "${JAVA_OPTS_ADD}" ]; then
  JAVA_OPTS="$JAVA_OPTS $JAVA_OPTS_ADD";
fi

# *_OVR variables are hard override parameters
# When hard override is specified, it is taken from ENV as it is - even if it is
# an empty string!
if [ ! -z "${CATALINA_OPTS_OVR+x}" ]; then
  CATALINA_OPTS="$CATALINA_OPTS_OVR";
fi
if [ ! -z "${JAVA_OPTS_OVR+x}" ]; then
  JAVA_OPTS="$JAVA_OPTS_OVR";
fi

# If you need to do something extra special, you can script it yourself.
# Files are taken from startTomcat.d/ in alphabetical order and SOURCED into this bash.
# Sourcing allows you to operate one the whole env if you need - this is a difference
# from runOnce.d and runEvery.d scripts which are just executed, not sourced.
# This is invoked every time the container starts.
echo "[$0] Sourcing files in order: $(ls $RUNSCRIPTS_PATH/startTomcat.d | tr '\n' ' ')";
for f in $(ls "$RUNSCRIPTS_PATH/startTomcat.d"); do
  echo "[$0] Sourcing file $f";
  . "$RUNSCRIPTS_PATH/startTomcat.d/$f";
done

export JAVA_HOME CATALINA_PID CATALINA_HOME CATALINA_BASE CATALINA_OPTS JAVA_OPTS
sudo -Eu tomcat /opt/tomcat/current/bin/catalina.sh run
