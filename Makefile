env: ## Start required containers: postgres and ruby
	@docker compose up -d

up: env ## alias for env

build: ## Re-build ruby container (if Dockerfile changes)
	@docker compose build

.docker-build: docker/Dockerfile
	@docker compose build
	@touch $@

bundle: env ## Run `bundle install` if necessary
	@docker compose exec api bash -c "bundle check || bundle install"

prepare_all: .docker-build env bundle

s: ## Fast start bash shell without environment checks
	@docker compose exec -it api bash

shell: prepare_all s ## Ensure environment is up and running and drop into shell in ruby container

sinatra: ## Start the rails server
	@docker compose exec api bundle exec rerun -- rackup --host 0.0.0.0 -p 4567

start: prepare_all sinatra ## Build and start full environment, run bundle install, ensure db is ready, and start rails server

down: ## Shut down containers
	@docker compose down

help: ## Print out this help message
	@egrep "^([a-zA-Z0-9_-]+):(.*)*##[[:blank:]]*(.*)" $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
