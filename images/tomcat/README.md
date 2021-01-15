# Tomcat image
Image built atop centos:7 with Apache Tomcat 9.0.x version. It has mountable dependencies that are only optional.
This image is a baseimage for our [CzechIdM identity manager container](https://github.com/bcvsolutions/czechidm-docker).

## Image versioning
This image is versioned by CzechIdM version. The underlying Tomcat version mentioned since CzechIdM is distributed as a whole application stack (well, without a database).

Naming scheme is pretty simple: **bcv-tomcat:TOMCAT_VERSION-rIMAGE_VERSION**.
- Image name is **bcv-tomcat**.
- **TOMCAT_VERSION** is a version of Apache Tomcat in the image.
- **IMAGE_VERSION** is an image release version written as a serial number, starting at 0. When images have the same CzechIdM versions but different image versions it means there were some changes in the image itself (setup scripts, etc.) but application itself did not change.

Example
```
bcv-tomcat:8.5.11-r0    // first release of Apache Tomcat 8.5.11 image
bcv-tomcat:8.5.11-r2    // third release of Apache Tomcat 8.5.11 image
bcv-tomcat:8.5.50-r0    // first release of Apache Tomcat 8.5.50 image
```

## Building
Simply cd to the directory which contains the Dockerfile and issue `docker build --no-cache -t <image tag here> ./`.

The build process:
1. Pulls **centos:7** image.
1. Updates binaries inside the image.
1. Installs JDK 11 (headless) and necessary tooling.
1. Downloads and sets up Apache Tomcat (for actual version, see top of the Dockerfile) to run under separate user **tomcat**.
1. Creates startup scripts structure inside **/runscripts** folder in the image. If you want to add your scripts to the runscripts, simply place them between sources and run the build process.

No security hardening is performed.

## Use
Image can be used without further configuration because it contains some defaults.
- Deploy directory is **/opt/tomcat/current/webapps**.
- Default Tomcat network ports (8080), no HTTPS configured.
- STDOUT/STDERR logging, logs available with `docker logs CONTAINER`.
- Xms512M
- Xmx1024M

Copy your application into the `/opt/tomcat/current/webapps/` or mount it into this directory (or mount the directory itself in RW mode - do as you wish). Tomcat will pick it up and deploy it.

## Container startup and hooks
Bootup process of the container:
1. Script **/runscripts/run.sh** is executed. This script allows you to set "breakpoints" that make script **sleep** for 3600 seconds in specific places. Those places are **RUNONCE_BREAKPOINT** (after script initialization, but before runOnce.sh is executed), **RUNEVERY_BREAKPOINT** (after runOnce.sh, but before runEvery.sh is executed), **STARTTOMCAT_BREAKPOINT** (after runEvery.sh, but before startTomcat.sh is executed). Those places allow you to connect into the container with `docker exec -it CONTAINER bash` and investigate its state and possible issues. To take effect, debug variable must be set but its contents do not matter.
1. The **run.sh** executes **/runscripts/runOnce.sh**.
  1. **runOnce.sh** checks if there is a **runOnce.done** file present. If it is, the **runOnce.sh** does nothing and exits.
  1. The **runOnce.done** contains timestamp of the time when **runOnce.sh** actually ran.
  1. If there is no **runOnce.done** file, it means the container was started for the first time ever and it may be necessary to perform some initialization steps.
  1. **runOnce.sh** executes all scripts in the **/runscripts/runOnce.d/** directory in an alphabetical order.
  1. You can hook up your custom runOnce script(s) by adding them into the **runOnce.d/**. Naming convention is: **IMAGENUM_SCRIPTNUM-userDefinedName.sh**.
    1. **IMAGENUM** - Number of image in the series. The Tomcat image has a number **000**. If you create new image atop the Tomcat image, you should use **001** as your image number.
    1. **SCRIPTNUM** - Serial number of the script for current image number. For example, if you already have **000_000-baseline.sh** script in the folder, you add another script as **000_001-doSomething.sh** (in case you remain in base image).
    1. **userDefinedName.sh** - Your naming of the script. The **.sh** suffix is mandatory.
1. After finishing with **runOnce.sh**, the run.sh executes **/runscripts/runEvery.sh** script.
  1. Philosophy of this script(s) is the same as for the **runOnce.sh** and **runOnce.d/**.
  1. Only difference is, the **runEvery.sh** is executed **every time the container starts**.
  1. Custom scripts are located in the **runEvery.d/** directory.
1. After finishing with **runEvery.sh**, the run.sh executes **startTomcat.sh**.
  1. This file is used to set startup options for Tomcat process.
  1. You can use a number of prepared variables.
  1. You can also hack away with custom scripts under **startTomcat.d/** directory. Philosophy is the same as before. **WARNING: Files under startTomcat.d/ are not just executed, they are SOURCED into startTomcat.sh. This allows you to modify environtment variables for Tomcat as you wish.**
1. The **startTomcat.sh** exports environment variables (JAVA_HOME, CATALINA_PID, CATALINA_HOME, CATALINA_BASE, CATALINA_OPTS, JAVA_OPTS) and executes the Tomcat process in foreground (as a separate user) using sudo.

All sh scripts run as **root** user, Tomcat runs as a **tomcat** user.

Tomcat image adds its own scripts there too:
- **runEvery.d/000_001-updateTimezone.sh** - This script updates container timezone according to the value in **TZ** variable, see the variable doc for details.
- **runEvery.d/000_002-generateJavaTruststore.sh** - This script generates (if not exists) and updates Tomcat Java truststore. It compares contents of `/opt/tomcat/truststore/certs/` directory with current truststore and updates the truststore accordingly - by removing obsolete and adding new certificates.
  - Certificates in the truststore are aliased by their backing file name. For example, certificate with alias `ad-ca.pem` is considered to have backing file `/opt/tomcat/truststore/certs/ad-ca.pem`. This comparison is done by name, so if you simply refresh the ad-ca.pem storing new certificate in there, the truststore **will not be updated**.
  - All certificates have to be in PEM format.
  - Resulting truststore is `/opt/tomcat/truststore/truststore.jks`.
  - Script generates (on-the-fly) new environment-adjusting file for the Tomcat, passing there truststore path and truststore password. This file is named `/runscripts/startTomcat.d/000_002-TomcatTruststoreOpts.sh`.

## Container shutdown
When initialized and running, the process tree in container looks like this:
```
run.sh
|___ startTomcat.sh
     |___ sudo -Eu tomcat /.../catalina.sh run
          |___ /usr/lib/jvm/java-openjdk ... parameters ... (Tomcat)
```
Upon shutdown, Docker sends `SIGTERM` to the **run.sh** process. This process traps the SIGTERM and sends it to **every process running under the tomcat user**, politely terminating the Tomcat application. The **run.sh** also waits until all processes of tomcat user terminate or until the **STOP_TIMEOUT** is reached. Afterwards, it waits another 1 second to let startTomcat.sh script terminate too.

Please note that Docker also implements timeout for container shutdowns. If the **STOP_TIMEOUT** is set too high, it may be overriden by Docker from the outside (Docker kills the container before stop timeout is reached).

## Environment variables
You can pass a number of environment variables into the container.
- **STOP_TIMEOUT** - Number of seconds (at most) the **run.sh** will wait for Tomcat to terminate. May be overriden by Docker itself (by killing the container). **Default: 15s**.
- **RUNONCE_BREAKPOINT** - When set (even to empty string), causes **run.sh** to sleep for 3600s so you can exec into the container and look around.
- **RUNEVERY_BREAKPOINT** - When set (even to empty string), causes **run.sh** to sleep for 3600s so you can exec into the container and look around.
- **STARTTOMCAT_BREAKPOINT** - When set (even to empty string), causes **run.sh** to sleep for 3600s so you can exec into the container and look around.
- **TZ** - Upon every start of the container, the current timezone is checked and set (TZ variable and /etc/localtime symlink). Set the timezone to suit your needs, syntax is [IANA tzdata](https://www.iana.org/time-zones) (the same you know from Linux). **Default: UTC**.
- **DOCKER_TOMCAT_ENABLE_FILE_LOGGING** - By default, there are file loggers defined in the Tomcat's logging.properties file, making Tomcat to log into container's filesystem. We get rid of it upon the **first start** of the container and redirect all logging to STDOUT/STDERR. If you want file-based logs to be written, set this variable (value does not matter). **Default: disabled**.
- **DOCKER_TOMCAT_DISABLE_ACCESS_LOG** - If this variable is set (even if empty), the Tomcat's access log is completely silenced. The application log is not affected by this setting. This option has no effect if Tomcat's file logging is enabled. **Default: disabled**.
- **DOCKER_TOMCAT_ENABLE_AJP** - On newer Tomcat versions, the AJP port is disabled by default. If this property is set (even if empty), Tomcat will be configured to use AJP port. **Default: disabled**.
- **DOCKER_TOMCAT_AJP_PASSFILE** - Path to a file with AJP port password. If not set, the AJP port will be configured as `requireSecret=false`. **Default: not set**.
- **JAVA_XMS** - Java Xms parameter. **Default: 512M**.
- **JAVA_XMX** - Java Xmx parameter. **Default: 1024M**.
- **CATALINA_OPTS_ADD** - What should be appended to CATALINA_OPTS variable. Default CATALINA_OPTS is `-Xms${JAVA_XMS} -Xmx${JAVA_XMX} -server -XX:+UseParallelGC`.
- **JAVA_OPTS_ADD** - What should be appended to JAVA_OPTS variable. Default JAVA_OPTS is `-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Djavax.servlet.request.encoding=UTF-8`.
- **CATALINA_OPTS_OVR** - If set, completely replaces contents of CATALINA_OPTS. Setting this variable to an empty string effectively removes any CATALINA_OPTS.
- **JAVA_OPTS_OVR** - If set, completely replaces contents of JAVA_OPTS. Setting this variable to an empty string effectively removes any JAVA_OPTS.

## Mounted files and volumes
- Optional
  - AJP port password file
    - This password protects Tomcat's AJP port.
    - Without this file mounted, the AJP port will be configured to not require password (any unauthenticated client can access it).
    - Example
      ```yaml
      volumes:
        - type: bind
          source: ./tomcat_ajp.pwfile
          target: /run/secrets/ajp.pwfile
          read_only: true
      ```
  - Trusted certificates directory
    - This directory contains certificates, that the Tomcat will trust. All certificates here **must** be in PEM format, their files names **without** spaces or special characters (`-` can be used).
    - Without this directory mounted, Tomcat will not trust any SSL certificate.
    - Example
      ```yaml
      volumes:
        - type: bind
          source: ./certs
          target: /opt/tomcat/truststore/certs
          read_only: true
      ```

## Forbidden variables
- **RUNSCRIPTS_PATH** - Defined in the Dockerfile and used during both build of the image and life of the container. This is a root folder from which the startup scripts locate each other. If you change it, the container start process will go haywire. For safety reasons, this variable is set as `readonly` in the **run.sh**.
- **TOMCAT_TRUSTSTORE** - Defined in the Dockerfile, this variable points to the directory where all trusted certificates magic happens. See runscript 000_002-generateJavaTruststore.sh for details.

## Hacking away
Once the container is created, there is no way to change its environment variables. This may get a bit clunky if you want to change some simple setting or when there is undesirable to destroy the container because of proper reconfiguration.

For further explanation how to get around this limitation, see **compose/env-override.sh**. Also please note, that this is a nonstandard way and it should be used with care. If you need to change settings and keep them so, it is way better to rebuild whole container.
