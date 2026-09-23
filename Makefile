# HG SDLC demo
#   make start    build if needed, start, wait until the framework is ready, open the tabs
#   make stop     stop the containers; containers and all data are kept
#   make restart  stop + start; nothing is lost
#   make reset    remove containers AND wipe all data (web app, board, framework runs)
# all state lives in ./shared: webapp.git, site/, board/, framework/ (db + run workspaces)
# the board and web app come pre-seeded with the demo run (see taskboard/seed-tasks.json
# and webapp/site/) so a fresh clone shows the same history as the screencast

SHELL := /bin/bash
UNAME := $(shell uname -s)
# OrbStack (macOS) installs docker here; not on PATH in every shell. Harmless elsewhere.
export PATH := $(HOME)/.orbstack/bin:$(PATH)

URLS := http://localhost:8081 http://localhost:8080 http://localhost:8082

.PHONY: start stop restart reset open status logs

start:
	@test -f hgsdlc/backend/build.gradle.kts || git submodule update --init
	@test -f .env || { echo "no .env: cp .env.example .env and put your OpenRouter key in it"; exit 1; }
	@docker info >/dev/null 2>&1 || $(MAKE) --no-print-directory _start-docker
	docker compose up -d --build
	@echo "waiting for the framework (first build can take ~5 min)..."
	@until docker compose exec -T framework test -e /tmp/setup.done -o -e /tmp/setup.failed 2>/dev/null; do sleep 3; done
	@docker compose logs --since 10m framework | grep '\[setup\]' | tail -8
	@docker compose exec -T framework test -e /tmp/setup.done || { echo "framework setup failed: make logs"; exit 1; }
	@$(MAKE) --no-print-directory open

# best-effort: launch a local docker runtime, then wait for it. Falls back to
# a clear message if we don't know how to start one on this machine/setup.
_start-docker:
	@if [ "$(UNAME)" = "Darwin" ] && [ -d "/Applications/OrbStack.app" ]; then \
		echo "starting OrbStack..."; open -a OrbStack; \
	elif [ "$(UNAME)" = "Darwin" ] && [ -d "/Applications/Docker.app" ]; then \
		echo "starting Docker Desktop..."; open -a Docker; \
	elif command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files docker.service >/dev/null 2>&1; then \
		echo "starting the docker service (needs sudo)..."; sudo systemctl start docker; \
	else \
		echo "Docker isn't running and I don't know how to start it here."; \
		echo "Start Docker/OrbStack/Colima yourself, then re-run: make start"; \
		exit 1; \
	fi
	@until docker info >/dev/null 2>&1; do sleep 2; done

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
	@if [ "$(UNAME)" = "Darwin" ]; then open -a Safari $(URLS) 2>/dev/null || open $(URLS); \
	elif command -v xdg-open >/dev/null 2>&1; then for u in $(URLS); do xdg-open $$u; done; \
	else echo "(open the three URLs above in your browser)"; fi

status:
	@docker compose ps -a

logs:
	docker compose logs -f --tail=50
