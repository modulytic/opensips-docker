all: build start

build:
	docker build -t opensips-docker ./

start:
	docker run -td --name opensips -p 80 -p 5060/udp --cap-add=NET_ADMIN opensips-docker