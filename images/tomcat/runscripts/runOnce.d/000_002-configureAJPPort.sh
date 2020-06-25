#!/bin/bash
echo "[$0] Configuring AJP port...";

if [ -z "${DOCKER_TOMCAT_ENABLE_AJP+x}" ]; then
  echo "[$0] Tomcat AJP port left on default (disabled).";
else
  echo "[$0] Enabling Tomcat AJP port...";
  cd /opt/tomcat/current/conf;
  xmlstarlet ed -L \
    -s 'Server/Service' -t elem -n 'Connector' -v 'ajpconnectortobeconfigured' \
    -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n 'protocol' -v 'AJP/1.3' \
    -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n 'address' -v '0.0.0.0' \
    -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n 'port' -v '8009' \
    -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n 'redirectPort' -v '8443' \
    server.xml;

    if [ -z "${DOCKER_TOMCAT_AJP_PASSFILE}" ]; then
      echo "[$0] DOCKER_TOMCAT_AJP_PASSFILE not set, configuring AJP port as secretRequired=false.";
      xmlstarlet ed -L \
        -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n "secretRequired" -v "false" \
        server.xml;
    else
      if [ -f "${DOCKER_TOMCAT_AJP_PASSFILE}" ]; then
        ajppass=$(cat "$DOCKER_TOMCAT_AJP_PASSFILE");
        xmlstarlet ed -L \
          -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n "secretRequired" -v "true" \
          -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n "secret" -v "$ajppass" \
          server.xml;
      else
        echo "[$0] DOCKER_TOMCAT_AJP_PASSFILE not readable, configuring AJP port as secretRequired=false.";
        xmlstarlet ed -L \
          -a "//Connector[text()='ajpconnectortobeconfigured']" -t attr -n "secretRequired" -v "false" \
          server.xml;
      fi
    fi

    #delete the "ajpconnectortobeconfigured" anchor
    xmlstarlet ed -L \
    -u "//Connector[text()='ajpconnectortobeconfigured']" -v "" \
    server.xml;

    echo "[$0] Tomcat AJP port configured.";
fi
