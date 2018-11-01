all: clean build docker

build: 
	- cd backend && make build 

docker:
	- cd backend && make docker

clean:
	- cd backend && make clean clean-docker
