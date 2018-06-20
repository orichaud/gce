GOCMD=/usr/local/bin/go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean

DOCKER=docker

SERVER=hserver
BASEDIR=.
BINDIR=./bin
SRCDIR=./src
DOCKERFILE=./Dockerfile
CONTAINER=hserver:v3
SERVERPORT=8080
DOCKER_REPO=eu.gcr.io
PROJECT=mp-box-dev

all: build

build: $(PKG)
	- mkdir -p $(BINDIR)
	cd $(SRCDIR) && GOOS=linux GOARCH=386 CGO_ENABLED=0 $(GOBUILD) -o ../$(BINDIR)/$(SERVER).linux ./main/$<
	cd $(SRCDIR) && GOOS=darwin GOARCH=386 CGO_ENABLED=0 $(GOBUILD) -o ../$(BINDIR)/$(SERVER).darwin ./main/$<
	cd $(BINDIR) && rm -f $(SERVER) && ln -s $(SERVER).linux $(SERVER)

docker: $(DOCKERFILE)
	$(DOCKER) build -t $(CONTAINER) --rm=true $(BASEDIR)
	$(DOCKER) tag $(CONTAINER) $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER)
	$(DOCKER) push $(DOCKER_REPO)/$(PROJECT)/$(CONTAINER)

clean:
	- rm -rf $(BINDIR)

clean-docker:
	- $(DOCKER) rmi -f $(CONTAINER)
	- $(DOCKER) rm -f $(CONTAINER)