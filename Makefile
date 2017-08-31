SHELL = /bin/sh
VERSION = v0.1
IMAGE_NAME = foreman

VOL_OPTS =
BUILD_OPTS =
RUN_OPTS =
EXEC_OPTS =

#User desired options for `docker run` \
#       and `foreman-installer --scenario katello` \
#       should be placed in file USER_OPTS
-include USER_OPTS

ifndef RUN_OPTS
#Default options to pass `docker run` if no user override defined
RUN_OPTS =  --hostname="localhost.localdomain" \
	-p 443:443 \
        -p 8443:8443 \
        -p 8140:8140
endif

ifndef EXEC_OPTS
#Default options to pass `foreman-installer --scenario katello` if no user override defined
EXEC_OPTS =  --enable-foreman-plugin-discovery \
        --foreman-plugin-discovery-source-url=http://downloads.theforeman.org/discovery/releases/3.0/ \
        --foreman-plugin-discovery-install-images=true \
        --enable-foreman-plugin-remote-execution \
        --enable-foreman-proxy-plugin-remote-execution-ssh
endif


all: build
build:
	docker build --pull -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME} .
	docker run -tdi --name ${IMAGE_NAME} ${RUN_OPTS} ${IMAGE_NAME}
	docker exec ${IMAGE_NAME} foreman-installer --scenario katello ${EXEC_OPTS}
	@if docker images ${IMAGE_NAME}:${VERSION}; then touch build; fi

lint:
	dockerfile_lint -f Dockerfile

test:
	docker build --pull -t ${IMAGE_NAME}:${VERSION} -t ${IMAGE_NAME} .
	docker run -tdi --name ${IMAGE_NAME} --hostname="localhost.localdomain" ${IMAGE_NAME}
	@sleep 5
	@docker exec ${IMAGE_NAME} foreman-installer --list-scenarios
	@docker exec ${IMAGE_NAME} foreman-installer --scenario katello --help
	@docker rm -f ${IMAGE_NAME}

clean:
	rm -f build