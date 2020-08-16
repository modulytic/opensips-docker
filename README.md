## Installing
Download to a local folder

```Bash
$ git clone https://github.com/modulytic/opensips-docker.git
$ cd opensips-docker
```

Build the docker image

```Bash
$ make build
```

Run the docker container

```Bash
$ make start
```

To log into the container to make configuration changes

```Bash
$ docker exec -it opensips /bin/bash
```
