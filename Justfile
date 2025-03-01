#DOCKER_REGISTRY=nboisvert
#DOCKER_TAG:=latest
#DOCKER_IMAGE=galerie:$(DOCKER_TAG)
#DOCKER_REMOTE_IMAGE=$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)

# Starts the dev environment by default
default: dev

# Fetches deps, setup assets and create the database
setup: deps setup-assets create-db reset-db

# Starts a development server
dev: create-db iex-server

# Install Node assets
setup-assets:
	npm install --prefix assets

# Creates database
create-db:
	mix ecto.create

# Resets database
reset-db:
	mix ecto.reset

# Starts an iex session
iex:
	iex -S mix

# Starts an iex session with Phoenix server
iex-server:
	iex -S mix phx.server

# Clean up dependencies
clean:
	rm -rf _build deps

# Clean dependencies and reinstall them
refresh: clean deps

# Install dependencies
deps:
	mix deps.get

