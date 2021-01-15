#!/bin/bash
echo "[$0] Creating Tomcat Java truststore...";

truststorepath="$TOMCAT_TRUSTSTORE/truststore.jks";
cd "$TOMCAT_TRUSTSTORE";
# check if truststore exists, if not, create one
if [ ! -f "truststore.jks" ]; then
  storepass=$(openssl rand -hex 10);
  # We can have this password lying around, it is in the process commandline anyway
  echo "$storepass" > truststore.pwfile;
  chmod 400 truststore.pwfile;

  openssl genrsa -out fakecert.key;
  openssl req -new -key fakecert.key -out fakecert.csr -subj "/C=CZ/ST=Czech Republic/L=Prague/O=BCV/CN=placeholder cert";
  openssl x509 -req -in fakecert.csr -signkey fakecert.key -days 1 -sha256 -out fakecert.crt;
  keytool -importcert -file fakecert.crt -alias placeholder-cert -keystore truststore.jks -storepass "$storepass" -noprompt;
  rm -f fakecert.key fakecert.csr fakecert.crt
  chmod 644 truststore.jks

  # add to tomcat java opts
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djavax.net.ssl.trustStore=$truststorepath -Djavax.net.ssl.trustStorePassword=$storepass\"" > "$RUNSCRIPTS_PATH/startTomcat.d/000_002-TomcatTruststoreOpts.sh";
fi

if [ ! -z "$(ls -A $TOMCAT_TRUSTSTORE/certs)" ]; then
  # trustcert directory is not empty, we import certificates
  storepass=$(cat truststore.pwfile);
  for crtfile in $TOMCAT_TRUSTSTORE/certs/*; do
    echo "[$0] Checking trusted cert entry for $crtfile ...";
    # import those certs we do not have already; alias=cert filename
    filename=$(basename "$crtfile");
    keytool -list -keystore truststore.jks -storepass "$storepass" | grep -q "^$filename";
    res=$?;
    if [ "$res" -ne "0" ]; then
      echo "[$0] Importing new trusted cert $crtfile as $filename ...";
      #cert not found, import it
      keytool -importcert -file "$crtfile" -alias "$filename" -keystore truststore.jks -storepass "$storepass"  -noprompt;
    else
      echo "[$0] Entry found, do nothing.";
    fi
  done
  for crtalias in $(keytool -list -keystore truststore.jks -storepass "$storepass" | grep -v "^placeholder-cert" | awk -F, '$0~/trustedCertEntry/ {print $1}'); do
    echo "[$0] Checking trusted cert file for alias $crtalias ...";
    # delete those trusted certs that are no longer in the trustcerts folder
    if [ ! -f "$TOMCAT_TRUSTSTORE/certs/$crtalias" ]; then
      echo "[$0] Certificate file for alias $crtalias not found, removing from truststore...";
      keytool -delete -alias "$crtalias" -keystore truststore.jks -storepass "$storepass"  -noprompt;
    else
      echo "[$0] Certificate file for alias $crtalias found, do nothing.";
    fi
  done

  # add to tomcat java opts
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djavax.net.ssl.trustStore=$truststorepath -Djavax.net.ssl.trustStorePassword=$storepass\"" > "$RUNSCRIPTS_PATH/startTomcat.d/000_002-TomcatTruststoreOpts.sh";
fi
