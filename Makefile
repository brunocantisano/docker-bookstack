.PHONY: default build remove rebuild save load tag push publish pull run test clean tty tty-mysql stop start

DOCKER_IMAGE_VERSION=0.25.1
IMAGE_NAME=bookstack
OWNER=devcant
PORT=9413
NEXUS_REPO=$(OWNER):$(PORT)
TAG=$(IMAGE_NAME):$(DOCKER_IMAGE_VERSION)
DOCKER_IMAGE_NAME=$(OWNER)/$(IMAGE_NAME)
DOCKER_IMAGE_TAGNAME=$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)
FILE_TAR = ./$(IMAGE_NAME).tar
FILE_GZ = $(FILE_TAR).gz

UNAME_S        := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    APP_HOST   := localhost
endif
ifeq ($(UNAME_S),Darwin)
    APP_HOST   := $(shell docker-machine ip default)
endif

default:
	build

build:
	docker build -t $(DOCKER_IMAGE_TAGNAME) .

remove:
	docker rmi -f $(DOCKER_IMAGE_TAGNAME)

rebuild: remove build

save:
	docker image save $(DOCKER_IMAGE_TAGNAME) > $(FILE_TAR)
	@[ -f $(FILE_TAR) ] && gzip $(FILE_TAR) || true

load:
	@[ -f $(FILE_GZ) ] && gunzip $(FILE_GZ) || true
	@[ -f $(FILE_TAR) ] && docker load -i $(FILE_TAR) && gzip $(FILE_TAR) || true

tag:
	docker tag $(DOCKER_IMAGE_TAGNAME) $(NEXUS_REPO)/$(TAG)

push:
	docker push $(NEXUS_REPO)/$(TAG)

publish: tag push

pull:
	docker pull $(NEXUS_REPO)/$(TAG)

run:
	$(eval ID := $(shell docker-compose up))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ http://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}

test:
	docker run --rm $(NEXUS_REPO)/$(TAG) /bin/echo "Success."

clean:
	@docker rm dockerbookstack_bookstack_1 dockerbookstack_bookstack_mysql_1 > /dev/null || true

tty:
	@docker exec -it dockerbookstack_bookstack_1 bash

tty-mysql:
	@docker exec -it dockerbookstack_bookstack_mysql_1 bash
	
stop:
	@docker stop dockerbookstack_bookstack_1 dockerbookstack_bookstack_mysql_1

start:
	@docker start dockerbookstack_bookstack_1 dockerbookstack_bookstack_mysql_1

all: build mount run import	