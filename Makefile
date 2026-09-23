# HG SDLC demo
#   make start    build if needed, start, wait until the framework is ready, open the tabs
#   make stop     stop the containers; containers and all data are kept
#   make restart  stop + start; nothing is lost
#   make reset    remove containers AND wipe all data (web app, board, framework runs)
# all state lives in ./shared: webapp.git, site/, board/, framework/ (db + run workspaces)

SHELL := /bin/bash
# OrbStack installs docker here; not on PATH in every shell
export PATH := $(HOME)/.orbstack/bin:$(PATH)

URLS := http://localhost:8081 http://localhost:8080 http://localhost:8082

.PHONY: start stop restart reset open status logs

start:
	@test -f hgsdlc/backend/build.gradle.kts || git submodule update --init
	@test -f .env || { echo "no .env: cp .env.example .env and put your OpenRouter key in it"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "starting OrbStack..."; open -a OrbStack; until docker info >/dev/null 2>&1; do sleep 2; done; }
	docker compose up -d --build
	@echo "waiting for the framework (first build can take ~5 min)..."
	@until docker compose exec -T framework test -e /tmp/setup.done -o -e /tmp/setup.failed 2>/dev/null; do sleep 3; done
	@docker compose logs --since 10m framework | grep '\[setup\]' | tail -8
	@docker compose exec -T framework test -e /tmp/setup.done || { echo "framework setup failed: make logs"; exit 1; }
	@$(MAKE) --no-print-directory open

stop:
	docker compose stop

restart: stop start

reset:
	@read -p "wipe ALL data (web app, board, framework runs) and remove containers? [y/N] " a; [ "$$a" = y ]
	docker compose down
	rm -rf shared
	@echo "wiped. make start to begin from scratch"

open:
	@echo "task board  http://localhost:8081"
	@echo "framework   http://localhost:8080  (admin / admin)"
	@echo "web app     http://localhost:8082"
	@open -a Safari $(URLS)

status:
	@docker compose ps -a

logs:
	docker compose logs -f --tail=50
