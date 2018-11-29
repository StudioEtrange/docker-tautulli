FROM debian:stretch
LABEL maintener "StudioEtrange <nomorgan@gmail.com>"
LABEL description "Tautulli on docker"

# PARAMETERS -------------------------------------------------------

# NOTE
# tautulli do not support python3.x

# Service generic parameters
ENV SERVICE_NAME tautulli
ENV SERVICE_VERSION v2.0.2-beta
# User id which will launch the service start command (NOTE : supervisord itself is run with root)
ENV SERVICE_USER 0
ENV SERVICE_PORT 8181
ENV SERVICE_INSTALL_DIR /opt/${SERVICE_NAME}

# Specific service parameters
# path to store service data and configuration
ENV SERVICE_DATA_PATH /data/${SERVICE_NAME}
# external paths used by service
ENV SERVICE_VOLUME_PATH ${SERVICE_DATA_PATH} /plexlogs
# args used by supervisor context for running service
ENV SERVICE_EXPORT_ARG SERVICE_DATA_PATH SERVICE_PORT SERVICE_INSTALL_DIR
ENV TAUTULLI_DOCKER True

# System parameters
ENV PYTHON_MAJOR_VERSION 2
ENV PYTHON_VERSION 2.7.15
ENV MINICONDA_VERSION 4.5.11
ENV CONDA_ENV ${SERVICE_NAME}
ENV PATH /opt/miniconda/bin:$PATH

# TREE FILESYSTEM --------------------------------------------------
RUN mkdir -p /etc/supervisor/conf.d && mkdir -p /var/log/supervisor && mkdir -p "${SERVICE_INSTALL_DIR}"

WORKDIR "${SERVICE_INSTALL_DIR}"



# COMPONENTS -------------------------------------------------------

# debian packages
RUN echo "deb http://httpredir.debian.org/debian stretch main non-free" >> /etc/apt/sources.list \
	&& echo "deb http://httpredir.debian.org/debian stretch-updates main non-free" >> /etc/apt/sources.list \
	&& echo "deb http://httpredir.debian.org/debian stretch-backports main non-free" >> /etc/apt/sources.list

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
					    ca-certificates curl wget openssl libssl-dev bzip2 unrar-free locales \
	&& rm -rf /var/lib/apt/lists/*

# locales
# https://stackoverflow.com/a/38553499
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

# Python
RUN MINICONDA_FILE=Miniconda${PYTHON_MAJOR_VERSION}-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    wget https://repo.continuum.io/miniconda/${MINICONDA_FILE} -O /opt/${MINICONDA_FILE} && \
    chmod +x /opt/$MINICONDA_FILE && \
    /opt/$MINICONDA_FILE -b -p /opt/miniconda && \
    rm /opt/$MINICONDA_FILE

# create dedicated environment
RUN /opt/miniconda/bin/conda create -y -n ${CONDA_ENV} python=${PYTHON_VERSION}

# install supervisor
RUN bash -c "source activate ${CONDA_ENV} && \
                pip install supervisor==3.3.4"

# SERVICE INSTALL -------------------------------------------------------
RUN curl -k -SL "https://github.com/Tautulli/Tautulli/archive/${SERVICE_VERSION}.tar.gz" \
	| tar -xzf - -C ${SERVICE_INSTALL_DIR} --strip-components=1


# SUPERVISOR -------------------------------------------------------
# add supervisor default configuration
COPY supervisord.conf /etc/supervisor/supervisord.conf
# add supervisor service configuration
COPY supervisord-${SERVICE_NAME}.conf /etc/supervisor/conf.d/supervisord-${SERVICE_NAME}.conf


# DOCKER RUN PARAMETERS ----------------------------------------------
# will contain service data and configuration
VOLUME /data
# will contain plex logs
VOLUME /plexlogs

# supervisor web interface
EXPOSE 9999

# service port
EXPOSE ${SERVICE_PORT}

# entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# default command
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
