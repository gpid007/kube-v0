sshpass -p 'AAasdf5asdf5' ssh greg@13.80.135.169


# source
https://hub.docker.com/r/v0rts/docker-centos7-cassandra/~/dockerfile/

# dockker pull
docker pull v0rts/docker-centos7-cassandra:latest

# check image
docker images

# show processes
docker ps

# rename
docker rename <old-name> <new-name>
docker rename unruffled_bhabha cassandra-centos

# execute
docker exec -ti cassandra-centos /bin/bash

