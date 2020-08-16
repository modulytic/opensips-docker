CONTAINER_NAME = opensips

all: build start

build:
	docker build -t $(CONTAINER_NAME) ./

start: build
	docker run -td --name $(CONTAINER_NAME) -p 3000:80 -p 8160:5060/udp --cap-add=NET_ADMIN $(CONTAINER_NAME)

restart:
	docker container restart $(CONTAINER_NAME)

rebuild: clean start

stop:
	docker container stop $(CONTAINER_NAME)

clean: stop
	docker container rm $(CONTAINER_NAME)