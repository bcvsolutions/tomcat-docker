FROM centos:7

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.56

ENV RUNSCRIPTS_PATH /runscripts

RUN yum install -y epel-release && \
		yum install -y deltarpm && \
		yum update -y && \
		yum install -y wget psmisc sudo java-1.8.0-openjdk-headless java-1.8.0-openjdk-devel xmlstarlet && \
		yum clean all

# The ddist() function is copied from
# https://github.com/docker-library/tomcat/blob/807a2b4f219d70f5ba6f4773d4ee4ee155850b0d/8.5/jdk8/openjdk/Dockerfile
# and stripped off PGP check. The ddist() code is under Apache License 2.0.
RUN mkdir -v /opt/tomcat && \
		ddist() { \
		local f="$1"; shift; \
		local distFile="$1"; shift; \
		local success=; \
		local distUrl=; \
		for distUrl in \
			'https://www.apache.org/dyn/closer.cgi?action=download&filename=' \
			https://www-us.apache.org/dist/ \
			https://www.apache.org/dist/ \
			https://archive.apache.org/dist/ \
		; do \
				if wget -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
					success=1; \
					break; \
				fi; \
			done; \
			[ -n "$success" ]; \
		}; \
		\
		ddist "/opt/tomcat/apache-tomcat-$TOMCAT_VERSION.tar.gz" "tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"; \
		\
		cd /opt/tomcat && \
		tar xzvf "apache-tomcat-$TOMCAT_VERSION.tar.gz" && \
		ln -sv "apache-tomcat-$TOMCAT_VERSION" current && \
		rm "apache-tomcat-$TOMCAT_VERSION.tar.gz"

RUN groupadd -r -g 998 tomcat && \
		useradd -r -u 999 -s /sbin/nologin -g tomcat -d /opt/tomcat tomcat && \
		getent passwd tomcat && \
		\
		chown -R root:root /opt/tomcat && \
		chown root:tomcat /opt/tomcat && \
		chmod 750 /opt/tomcat && \
		cd /opt/tomcat/current && \
		chmod o+rX -R ./ && \
		chgrp -R tomcat conf/ bin/ lib/ && \
		chmod g+rwx conf && \
		chmod g+r conf/* && \
		chown -R tomcat webapps/ work/ temp/ logs/ && \
		\
		mkdir -pv "$RUNSCRIPTS_PATH"

COPY runscripts "$RUNSCRIPTS_PATH/"
RUN find "$RUNSCRIPTS_PATH/" -name "*.sh" -exec chmod -v u+x {} \;

COPY dropin/tomcat-stdout-accesslog*.jar /opt/tomcat/current/lib/

CMD ["/bin/bash","-c","$RUNSCRIPTS_PATH/run.sh"]

EXPOSE 8009/tcp
EXPOSE 8080/tcp

# This is for documentation purposes only and intentionally commented-out.
# If enabled, it effectively disallows downstream Dockerfiles to modify contents
# of those directories during image build phase.
#VOLUME ["/opt/tomcat/current/webapps"]
#VOLUME ["/opt/tomcat/current/logs"]
