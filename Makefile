.PHONY=all \
	db-status db-start db-stop db-clean db-repl \
	supafana-deps supafana-compile supafana-repl supafana-clean \
	clean clean-all

PG_DATA=.nix-shell/db

PG_CTL=pg_ctl -D ${PG_DATA} -l "${PG_DATA}/server.log" -o "-h ${PG_HOST} -p ${PG_PORT} -k ."

all: supafana-repl

db-status:
	${PG_CTL} status

db-start: | ${PG_DATA}
	${PG_CTL} status || ${PG_CTL} start

${PG_DATA}:
	mkdir -p ${PG_DATA}
	initdb -D ${PG_DATA} --no-locale --encoding=UTF8
	${MAKE} db-start db-create db-stop

db-stop:
	${PG_CTL} status && ${PG_CTL} stop || exit 0

db-clean: db-stop
	rm -rf ${PG_DATA}

db-reset: db-clean db-start db-migrate

db-create: db-start db-create-db

db-create-db:
	createuser -h ${PG_HOST} -p ${PG_PORT} ${PG_USER} --createdb --echo --superuser
	createdb -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} ${PG_DB}

db-update-user-role: db-start
	psql -c "ALTER ROLE ${PG_USER} SUPERUSER;" -h ${PG_HOST} -p ${PG_PORT} -d ${PG_DB}

db-repl: db-start
	psql -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} -d ${PG_DB}

db-migrate: db-start
	cd server && mix ecto.migrate && mix ecto.dump -d ./priv/repo/db-dump.sql

db-rollback: db-start
	cd server && mix ecto.rollback && mix ecto.dump -d ./priv/repo/db-dump.sql

supafana-deps:
	cd server && mix deps.get

supafana-deps-clean:
	cd server && mix deps.clean --unused --unlock

supafana-deps-nix: supafana-deps supafana-deps-clean
	cd server && mix mix_to_json

supafana-compile: supafana-deps
	cd server && mix compile

supafana-repl: supafana-compile db-migrate
	cd server && iex -S mix

supafana-clean:
	cd server && mix clean

supafana-format:
	cd server && mix format

supafana-format-check:
	cd server && mix format --check-formatted

supafana-bump:
	scripts/calver bump "$$(cat server/VERSION)" > server/VERSION
	git add -- server/VERSION
	git commit -m "supafana $$(cat server/VERSION)"
	git tag -a "supafana-$$(cat server/VERSION)" -m "supafana version bump"

supafana-test: db-start
	cd server && MIX_ENV=test mix do ecto.create --quiet, ecto.migrate && mix test ${TEST_FILE}

supafana-test-watch: db-start
	cd server && MIX_ENV=test mix do ecto.create --quiet, ecto.migrate && mix test.watch

supafana-test-no-deps-check: db-start
	cd server && MIX_ENV=test mix ecto.migrate --no-deps-check && mix test --trace --no-deps-check

supafana-test-wip-watch: db-start
	cd server && MIX_ENV=test mix do ecto.create --quiet, ecto.migrate && mix test.watch --only wip


clean: supafana-clean

web-format:
	cd storefront && pnpm fmt

format: web-format supafana-format

web-start:
	cd storefront && pnpm install && pnpm dev
