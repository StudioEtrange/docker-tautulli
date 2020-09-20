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

	mkdir -p data
	docker run --name tautulli -d -v $(pwd)/data:/data -p 8181:8181 studioetrange/docker-tautulli

then go to http://localhost:8181

## Docker tags

Pre-setted buildable docker tags for studioetrange/docker-tautulli:__TAG__

	latest, v2.5.5, v2.5.4, v2.5.3, v2.5.2, v2.5.2-beta, v2.5.1-beta, v2.5.0-beta, v2.2.4, v2.2.3, v2.2.3-beta, v2.2.2-beta, v2.2.1, v2.2.0, v2.2.0-beta, v2.1.44, v2.1.43, v2.1.42

Current latest tag is version __v2.5.5__

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
