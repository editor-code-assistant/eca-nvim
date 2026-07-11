# Makefile for ECA Neovim plugin testing

.PHONY: test deps clean compile check-compiled

# Download dependencies for testing
deps: deps/plenary.nvim

deps/plenary.nvim:
	mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-lua/plenary.nvim.git deps/plenary.nvim

# Compile all .fnl sources to .lua using the vendored nfnl compiler.
# Depends only on the nvim binary — nfnl (compiler, fennel, macros) is in-repo.
compile:
	nvim --headless -u NONE --noplugin \
  	-c "set rtp^=." \
  	-c "lua require('eca.nfnl.api')['compile-all-files']('.')" \
  	-c "qa!"

# Fail if committed .lua is out of sync with .fnl (e.g. someone forgot to compile).
check-compiled: compile
	@git diff --exit-code -- lua/ || \
  	  { echo "ERROR: compiled .lua is stale — run 'make compile' and commit the result"; exit 1; }

# Run all tests
test: deps
	nvim --headless -u NONE --noplugin \
  	-c "set rtp^=deps/plenary.nvim" \
  	-c "lua require('plenary.test_harness').test_directory_command(\"lua/spec\")"

# Clean up dependencies
clean:
	rm -rf deps/
