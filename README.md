# tomcat-docker
BCV docker image for Apache Tomcat.
This image can be used as general-purpose image.

This image is built atop CentOS 7 baseimage. All additional applications, modules, connectors, configuration, etc. are supposed to be built atop existing docker image, effectively creating new docker image.

## Directory structure
- **compose/** - contains simple/sample docker-compose files for images from this repo.
- **images/** - contains sources for building docker images.

## Additional info
- See [README.md](compose/README.md) in **compose/** for compose YAML files and for starting image as a part of the infrastructure.
- See [README.md](images/tomcat/README.md) in **images/tomcat/** to get more information about the docker image.
