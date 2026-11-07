.PHONY: test deps clean compile check-compiled lint fmt fmt-check style

STYLE_FLAGS ?=
FENNEL_LS ?= $(shell command -v fennel-ls 2>/dev/null || printf '%s' '$(HOME)/.local/share/nvim/mason/bin/fennel-ls')
LINT_FILES ?= $(shell find fnl -type f \( -name '*.fnl' -o -name '*.fnlm' \) ! -path 'fnl/eca/nfnl/*' -exec sh -c 'head -n 1 "$$1" | grep -qF '[nfnl-macro]' || printf "%s " "$$1"' _ {} \;)

deps: deps/plenary.nvim

deps/plenary.nvim:
	mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-lua/plenary.nvim.git deps/plenary.nvim

compile:
	nvim --clean --headless \
  	-c "set rtp^=." \
  	-c "lua require('eca.nfnl.api')['compile-all-files']('.')" \
  	-c "qa!"

check-compiled: compile
	@git diff --exit-code -- lua/ || \
  	  { echo "ERROR: compiled .lua is stale — run 'make compile' and commit the result"; exit 1; }

lint:
	@if ! command -v "$(FENNEL_LS)" >/dev/null 2>&1; then \
	  echo "fennel-ls not found; install it (e.g. via Mason or luarocks) or set FENNEL_LS=/path"; \
	  exit 1; \
	fi
	"$(FENNEL_LS)" --lint $(LINT_FILES)

fmt:
	scripts/fennel-extras format --write

fmt-check:
	scripts/fennel-extras format --check

style:
	scripts/fennel-extras lint $(STYLE_FLAGS)

test: deps
	nvim --headless --noplugin -u scripts/minimal_init.lua \
  	-c "lua require('plenary.test_harness').test_directory_command(\"lua/spec { minimal_init = 'scripts/minimal_init.lua' }\")"

# Clean up dependencies
clean:
	rm -rf deps/
