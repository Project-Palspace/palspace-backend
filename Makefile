default: help

help:
	@cat docs/help.txt
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

build:
	docs/build.sh

build-runner:
	dart run build_runner build --delete-conflicting-outputs
	
up:
	cd docker/;	docker compose up -d

down:
	cd docker/;	docker compose down

dev:
	make build
	make up

dev-local:
	dart pub get
	make build-runner
	dart run bin/server.dart

set-hosts:
	echo "127.0.0.1    api.palspace.dev" | sudo tee -a /etc/hosts
	echo "127.0.0.1    obj.palspace.dev" | sudo tee -a /etc/hosts
	echo "127.0.0.1    obj-portal.palspace.dev" | sudo tee -a /etc/hosts
	echo "127.0.0.1    proxy.palspace.dev" | sudo tee -a /etc/hosts

update:
	git pull
	make dev

import-certs:
	docs/certs.sh

restart:
	docker restart palspace-palspace-backend-1

log:
	docker logs --follow palspace-palspace-backend-1