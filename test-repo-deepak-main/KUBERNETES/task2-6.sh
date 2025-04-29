#!/bin/bash

# Start the first NGINX container on port 80
docker run -d --name nginx-80 -p 80:80 nginx

# Start the second NGINX container on port 8080 (changed to avoid conflict)
docker run -d --name nginx-8080 -p 8080:80 nginx


