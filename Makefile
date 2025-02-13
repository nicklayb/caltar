.PHONY: dev iex create-db docker-build docker-tag docker-push release-docker iex-server down clean deps setup

DOCKER_REGISTRY=nboisvert
DOCKER_TAG:=latest
DOCKER_IMAGE=galerie:$(DOCKER_TAG)
DOCKER_REMOTE_IMAGE=$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)

setup: asdf-install deps setup-assets create-db reset-db

dev: create-db iex-server

asdf-install:
	asdf install

setup-assets:
	npm install --prefix assets

create-db:
	mix ecto.create

reset:
	mix ecto.reset

boot-db:
	docker compose up -d db

boot-docker:
	docker compose up -d

iex:
	iex -S mix

iex-server:
	iex -S mix phx.server

release-docker: docker-build docker-tag docker-push

destroy-docker:
	docker compose down --volumes

down:
	docker compose down

clean:
	rm -rf _build deps

refresh: clean deps

fresh-start: destroy-docker clean setup

deps:
	mix deps.get

