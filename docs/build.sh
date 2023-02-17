#!/bin/bash
sudo chown $USER -R docker/ingress/nginx/
sudo chmod 777 -R docker/ingress/nginx/
cd docker/ingress/nginx/; find . -type f  ! -name "*.*"  -delete
cd ../../../; docker build -t palspace-backend .
