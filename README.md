# docker tautulli by StudioEtrange

* Run tautulli inside a docker container built upon debian
* Based on tautulli github repository
* Choice of tautulli version
* Use supervisor to manage tautulli process
* Can choose a specific unix user to run tautulli inside docker
* By default tautulli configuration files will be in a folder named 'tautulli' which will be contained in a docker volume /data


## Quick Usage

for running latest stable version of tautulli :

	docker run -d -v $(pwd):/data -p 8181:8181 studioetrange/docker-tautulli

then go to http://localhost:8181

## Docker tags

Available tag for studioetrange/docker-tautulli:__TAG__

	latest, v3.0.3988, v3.0.3945, v3.0.3923, v3.0.3919, v3.0.3795, v3.0.3786, v3.0.3776, v3.0.3587, v3.0.3477, v3.0.3421, v3.0.3407, v3.0.3383, v3.0.3368, v3.0.3346, v3.0.3330, v3.0.3304, v3.0.3293, v3.0.3268, v3.0.3239, v3.0.3185, v3.0.3173, v3.0.3164, v3.0.3111, v3.0.3030, v3.0.3020, v3.0.3000, v3.0.2970, v2.2.1, v2.2.0, v2.1.0, v2.0.1, v1.10.1, v1.10.0, v1.9.7, v1.9.6, v1.9.5, v1.9.4, v1.9.3, v1.9.2, v1.9.1, v1.9.0, v1.8.4, v1.8.3, v1.8.2, v1.8.1, v1.8.0, v1.7.5, v1.7.4, v1.7.3, v1.7.2, v1.7.1, v1.7.0, v1.6.1, v1.6.0, v1.5.2, v1.5.1, v1.5.0, v1.4.1, v1.4.0, v1.3.0, v1.2.1, v1.2.0, v1.1

Current latest tag is version __v3.0.3988__

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
`/data/tautulli` will contain tautulli configuration
`/plexlogs` is the root folder of your plex logs

If host `<data path>` or `<plex logs path>` does not exist, docker will create it automaticly with root user. You should use mkdir before launching docker to control ownership.

### Access supervisor control inside a running instance

	docker exec -it tautulli bash -c ". activate tautulli && supervisorctl"

### Test a shell inside a new container without tautulli running

	docker run -it studioetrange/docker-tautulli bash

## Access point

### tautulli

	Go to http://localhost:TAUTULLI_HTTP_PORT/

### Supervisor process manager

	Go to http://localhost:SUPERVISOR_HTTP_WEB/

## Notes on Github / Docker Hub Repository

* This github repository is linked to an automated build in docker hub registry.

	https://registry.hub.docker.com/u/studioetrange/docker-tautulli/

* _update.sh_ is only an admin script for this project which update and add new versions. This script do not auto create missing tag in docker hub webui. It is only for this project admin/owner purpose.
