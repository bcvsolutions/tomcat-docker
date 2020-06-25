#!/bin/bash
echo "[$0] Checking if Tomcat should log only on console...";

if [ -z "${DOCKER_TOMCAT_ENABLE_FILE_LOGGING+x}" ]; then
  cd /opt/tomcat/current/conf;
  # direct all apps to stdout
  sed -e '/^[1-4]\|^#\|^$\|^\s+#/d' \
      -e 's/[1-4].*AsyncFileHandler, *//g' \
      -e 's/[1-4].*AsyncFileHandler$/java.util.logging.ConsoleHandler/' \
      -i logging.properties
  # direct access log to stdout - must use external valve,
  # redirecting to /proc/self/fd/1 does not work reliably
  # using this: https://github.com/Scout24/tomcat-stdout-accesslog built locally and
  # accessible in the dropin/ directory.
  xmlstarlet ed -L \
     -d "//Valve[@className = 'org.apache.catalina.valves.AccessLogValve']/@directory" \
     -d "//Valve[@className = 'org.apache.catalina.valves.AccessLogValve']/@prefix" \
     -d "//Valve[@className = 'org.apache.catalina.valves.AccessLogValve']/@suffix" \
     server.xml;

  if [ -z "${DOCKER_TOMCAT_DISABLE_ACCESS_LOG+x}" ]; then
    #the variable is not set, so we will enable access logging
    xmlstarlet ed -L \
      -u "//Valve[@className = 'org.apache.catalina.valves.AccessLogValve']/@className" -v "de.is24.tomcat.StdoutAccessLogValve" \
     server.xml;
  else
    #variable is set, so we sill get rid of access log altogether
    xmlstarlet ed -L \
      -d "//Valve[@className = 'org.apache.catalina.valves.AccessLogValve']" \
     server.xml;
  fi

  echo "[$0] Tomcat now logging only on STDOUT/STDERR.";
else
  echo "[$0] Tomcat logging left as-is, even to files inside container.";
fi
