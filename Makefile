TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests/

.PHONY: test

test: deps
	@nvim --headless --noplugin -u ${TESTS_INIT} -c "lua MiniTest.run()"

test_file: deps
	@nvim --headless --noplugin -u ${TESTS_INIT} -c "lua MiniTest.run('$(FILE)')"

# it might be useful to figure out a good way to install lpeg using the makefile
deps:
	mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim deps/mini.nvim
	git clone --filter=blob:none https://github.com/pygy/LuLPeg deps/LuLPeg/lua
	git clone --filter=blob:none https://github.com/MunifTanjim/nui.nvim deps/nui.nvim
