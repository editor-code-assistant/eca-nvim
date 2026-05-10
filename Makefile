# Makefile for ECA Neovim plugin testing

.PHONY: test deps clean

# Download dependencies for testing
deps: deps/plenary.nvim

deps/plenary.nvim:
	mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-lua/plenary.nvim.git deps/plenary.nvim

# Run all tests
test: deps
	./script/test

# Clean up dependencies
clean:
	rm -rf deps/
