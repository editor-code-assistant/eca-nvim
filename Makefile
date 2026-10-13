.PHONY: test deps clean compile check-compiled

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

test: deps
	nvim --headless --noplugin -u scripts/minimal_init.lua \
  	-c "lua require('plenary.test_harness').test_directory_command(\"lua/spec { minimal_init = 'scripts/minimal_init.lua' }\")"

# Clean up dependencies
clean:
	rm -rf deps/
