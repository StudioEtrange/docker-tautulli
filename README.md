# docker tautulli by StudioEtrange

* Run tautulli inside a docker container built upon debian
* Based on tautulli github repository
* Choice of tautulli version
* Use supervisor to manage tautulli process
* Can choose a specific unix user to run tautulli inside docker
* By default tautulli configuration files will be in a folder named 'tautulli' which will be contained in a docker volume /data
* Optional volume 'plexlogs' used to connect plex logs

## Quick Usage

for running latest stable version of tautulli :

	docker run --name tautulli -d -v $(pwd):/data -p 8181:8181 studioetrange/docker-tautulli

then go to http://localhost:8181

## Docker tags

Available tag for studioetrange/docker-tautulli:__TAG__

	latest, v2.1.26, v2.1.25, v2.1.24-beta, v2.1.23-beta, v2.1.22, v2.1.21, v2.1.20, v2.1.20-beta, v2.1.19-beta, v2.1.18, v2.1.17-beta, v2.1.16-beta, v2.1.15-beta, v2.1.14, v2.1.13, v2.1.12, v2.1.11-beta, v2.1.10-beta, v2.1.9, v2.1.8-beta, v2.1.7-beta, v2.1.6-beta, v2.1.5-beta, v2.1.4, v2.1.3-beta, v2.1.2-beta, v2.1.1-beta, v2.1.0-beta, v2.0.28, v2.0.27, v2.0.26-beta, v2.0.25, v2.0.24, v2.0.23-beta, v2.0.22, v2.0.22-beta, v2.0.21-beta, v2.0.20-beta, v2.0.19-beta, v2.0.18-beta, v2.0.17-beta, v2.0.16-beta, v2.0.15-beta, v2.0.14-beta, v2.0.13-beta, v2.0.12-beta, v2.0.11-beta, v2.0.10-beta, v2.0.9-beta, v2.0.8-beta, v2.0.7-beta, v2.0.6-beta, v2.0.5-beta, v2.0.4-beta, v2.0.3-beta, v2.0.2-beta, v2.0.1-beta, v2.0.0-beta, v1.4.25, v1.4.24, v1.4.23, v1.4.22, v1.4.21, v1.4.20, v1.4.19, v1.4.18, v1.4.17, v1.4.16, v1.4.15, v1.4.14, v1.4.13, v1.4.12, v1.4.11, v1.4.10, v1.4.9, v1.4.8, v1.4.7, v1.4.6, v1.4.5, v1.4.4, v1.4.3, v1.4.2, v1.4.1, v1.4.0, v1.3.16, v1.3.15, v1.3.14, v1.3.13, v1.3.12, v1.3.11, v1.3.10, v1.3.9, v1.3.8, v1.3.7, v1.3.6, v1.3.5, v1.3.4, v1.3.3, v1.3.2, v1.3.1, v1.3.0, v1.2.16, v1.2.15, v1.2.14, v1.2.13, v1.2.12, v1.2.11, v1.2.10, v1.2.9, v1.2.8, v1.2.7, v1.2.6, v1.2.5, v1.2.4, v1.2.3, v1.2.2, v1.2.1, v1.2.0, v1.1.10, v1.1.9, v1.1.8, v1.1.7, v1.1.6, v1.1.5, v1.1.4, v1.1.3, v1.1.2, v1.1.1, v1.1.0, v1.0.1, v1.0

Current latest tag is version __v2.1.26__

## Instruction

### Build from github source

	git pull https://github.com/StudioEtrange/docker-tautulli
	cd docker-tautulli
	docker build -t=studioetrange/docker-tautulli .

### Retrieve image from docker registry

	docker pull studioetrange/docker-tautulli

### Standard usage

	mkdir -p data
	docker run --name tautulli -d -v $(pwd)/data:/data -p 8060:8181 -e SERVICE_USER=$(id -u):$(id -g) -v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro studioetrange/docker-tautulli

### Full run parameters

	docker run --name tautulli -d -v <data path>:/data -v <plex logs path>:/plexlogs -p <tautulli http port>:8181 -e SERVICE_USER=<uid[:gid]>  -p <supervisor manager http port>:9999 -v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro studioetrange/docker-tautulli:<version>

### Volumes

Inside container
`/data/tautulli` will contain medusa tautulli and files
`/plexlogs` is the root folder of your plex logs

If any path of theses volumes do not exist on the host while your are mounting them inside container, docker will create it automaticly with root user. You should use mkdir before launching docker to control ownership.


### Access to a running instance

supervisorctl access

	docker exec -it tautulli bash -c ". activate tautulli && supervisorctl"
	
bash access

	docker exec -it tautulli bash -c ". activate tautulli"

### Test a shell inside a new container without tautulli running

	docker run -it --rm studioetrange/docker-tautulli bash
	
### Stop and destroy all previously launched services

	docker stop tautulli && docker rm tautulli

## Access point

### tautulli

	Go to http://localhost:TAUTULLI_HTTP_PORT/

### Supervisor process manager

	Go to http://localhost:SUPERVISOR_HTTP_WEB/

## Notes on Github / Docker Hub Repository

* This github repository is linked to an automated build in docker hub registry.

	https://registry.hub.docker.com/u/studioetrange/docker-tautulli/

* _update.sh_ is only an admin script for this project which update and add new versions. This script do not auto create missing tag in docker hub webui. It is only for this project admin/owner purpose.
