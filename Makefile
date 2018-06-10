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
SERVERPORT=8080

all: build

build: $(PKG)
	- mkdir -p $(BINDIR)
	cd $(SRCDIR) && GOOS=linux GOARCH=386 CGO_ENABLED=0 $(GOBUILD) -o ../$(BINDIR)/$(SERVER).linux ./main/$<
	cd $(SRCDIR) && GOOS=darwin GOARCH=386 CGO_ENABLED=0 $(GOBUILD) -o ../$(BINDIR)/$(SERVER).darwin ./main/$<
	cd $(BINDIR) && rm -f $(SERVER) && ln -s $(SERVER).linux $(SERVER)

docker: $(DOCKERFILE)
	$(DOCKER) build -t $(CONTAINER) --rm=true $(BASEDIR)
	$(DOCKER) tag $(CONTAINER) eu.gcr.io/mp-box-dev/$(CONTAINER)
	$(DOCKER) push eu.gcr.io/mp-box-dev/$(CONTAINER)

clean:
	- rm -rf $(BINDIR)

clean-docker:
	- $(DOCKER) rmi -f $(CONTAINER)
	- $(DOCKER) rm -f $(CONTAINER)