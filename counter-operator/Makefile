DOCKER=docker

CONTAINER=counter-operator
VERSION=v1
DOCKER_REPO=eu.gcr.io
PROJECT=mp-box-dev

docker:
	rm -rf descriptors
	mkdir descriptors
	cp ../descriptors/{redis,counter}-{deployment,service}.yaml descriptors
	GO111MODULE=on operator-sdk build $(CONTAINER):$(VERSION)
	rm -rf descriptors
	$(DOCKER) tag $(CONTAINER):$(VERSION) $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER):$(VERSION)
	$(DOCKER) push $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER):$(VERSION)
	$(DOCKER) images

clean-docker:
	- $(DOCKER) rmi -f $(CONTAINER):$(VERSION)
	- $(DOCKER) rmi -f $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER):$(VERSION)