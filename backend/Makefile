GOCMD=/usr/local/bin/go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean

DOCKER=docker

SERVER=hserver
BASEDIR=.
BINDIR=./bin
SRCDIR=./src
DOCKERFILE=./Dockerfile
CONTAINER=hserver
VERSION=v3
SERVERPORT=8080
DOCKER_REPO=eu.gcr.io
PROJECT=mp-box-dev

all: clean clean-docker build docker

build: $(PKG)
	- mkdir -p $(BINDIR)
	cd $(SRCDIR) && GOOS=linux GOARCH=386 CGO_ENABLED=0 $(GOBUILD) -o ../$(BINDIR)/$(SERVER).linux ./main/$<
	cd $(SRCDIR) && GOOS=darwin GOARCH=386 CGO_ENABLED=0 $(GOBUILD) -o ../$(BINDIR)/$(SERVER).darwin ./main/$<
	cd $(BINDIR) && rm -f $(SERVER) && ln -s $(SERVER).linux $(SERVER)

docker: $(DOCKERFILE)
	$(DOCKER) build -t $(CONTAINER):$(VERSION) --rm=true $(BASEDIR)
	$(DOCKER) tag $(CONTAINER):$(VERSION) $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER):$(VERSION)
	$(DOCKER) push $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER):$(VERSION)
	$(DOCKER) images

clean:
	- rm -rf $(BINDIR)

clean-docker:
	- $(DOCKER) rmi -f $(CONTAINER):$(VERSION)
	- $(DOCKER) rmi -f $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER):$(VERSION)
