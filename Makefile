#!/usr/bin/make -f

#-------------------------------------------------------------------------------
# Docker variables
#-------------------------------------------------------------------------------
DOCKER_IMAGE_NAME=eks-manager
DOCKER_IMAGE_VERSION=$(shell cat VERSION)

DOCKER_TAGNAME_VERSION=${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
DOCKER_TAGNAME_LATEST=${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:latest

#-------------------------------------------------------------------------------
# echo
#-------------------------------------------------------------------------------
.PHONY: echo
echo:
	@echo "-- Image coordinates"
	@echo DOCKER_IMAGE_NAME=[${DOCKER_IMAGE_NAME}]
	@echo VERSION=[${DOCKER_IMAGE_VERSION}]
	#
	@echo "-- Image tags"
	@echo DOCKER_TAGNAME_VERSION=${DOCKER_TAGNAME_VERSION}
	@echo DOCKER_TAGNAME_LATEST=${DOCKER_TAGNAME_LATEST}
	#
	@echo "-- Registry Credentials"
	@echo DOCKER_USERNAME=[${DOCKER_USERNAME}]
	@echo DOCKER_PASSWORD=[${DOCKER_PASSWORD}]


#-------------------------------------------------------------------------------
# Build
#-------------------------------------------------------------------------------
.PHONY: build
build:
	#-- build image
	docker build \
		-t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION} \
		-f Dockerfile \
		.

#-------------------------------------------------------------------------------
# Docker publish
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
.PHONY: docker-login
docker-login:
	docker login -u $(DOCKER_USERNAME) -p $(DOCKER_PASSWORD)


#-------------------------------------------------------------------------------
.PHONY: docker-push-version
docker-push-version: docker-login
	#
	docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION} ${DOCKER_TAGNAME_VERSION}
	#
	docker push ${DOCKER_TAGNAME_VERSION}
	#
	docker logout

#-------------------------------------------------------------------------------
.PHONY: docker-push-latest
docker-push-latest: docker-login
	#
	docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION} ${DOCKER_TAGNAME_LATEST}
	#
	docker push ${DOCKER_TAGNAME_LATEST}
	#
	docker logout

#-------------------------------------------------------------------------------
# pull
#-------------------------------------------------------------------------------
.PHONY: pull
pull:
	docker pull ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}


#-------------------------------------------------------------------------------
.PHONY: run
run:
	docker run \
		-it --rm \
		-e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
		-e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
		-v ${PWD}/workdir/:/workdir \
		-e DOCKER_USER_ID=$(shell id -u) \
	  -e DOCKER_GROUP_ID=$(shell id -g) \
		${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
