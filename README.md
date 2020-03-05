# tomcat-docker
BCV docker image for Apache Tomcat.
This image can be used as general-purpose image.

This image is built atop CentOS 7 baseimage. All additional applications, modules, connectors, configuration, etc. are supposed to be built atop existing docker image, effectively creating new docker image.

## Directory structure
- **compose/** - contains simple/sample docker-compose files for images from this repo.
- **images/** - contains sources for building docker images.

## Additional info
- Release tags on this repository correspond to release tags on individual images.
- See **README.md** in [images/tomcat/](images/tomcat/) to get more information about the docker image.
- See **README.md** in [compose/](compose/) for compose YAML files and for starting image as a part of the infrastructure.
