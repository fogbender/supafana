.PHONY=all \
	     supafana-deps supafana-compile supafana-repl supafana-clean \
	     clean clean-all

all: supafana-repl

supafana-deps:
	cd server && mix deps.get

supafana-deps-clean:
	cd server && mix deps.clean --unused --unlock

supafana-deps-nix: supafana-deps supafana-deps-clean
	cd server && mix mix_to_json

supafana-compile: supafana-deps
	cd server && mix compile

supafana-repl: supafana-compile
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

clean: supafana-clean

web-format:
	cd storefront && pnpm fmt

format: web-format supafana-format
