default: help


help:
	docs/help.sh

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
	docs/hosts.sh

update:
	make down
	git pull
	make build
	make up

import-certs:
	docs/certs.sh

restart:
	docker restart palspace-palspace-backend-1

log:
	docker logs --follow palspace-palspace-backend-1

lint:
	dart format .
