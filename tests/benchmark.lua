vim.opt.rtp:append("deps/LuLPeg")

local regex_railroad = require("regex-railroad")

regex_railroad.setup({ clear = true })

local utils = dofile("tests/utils.lua")

local expressions = utils.get_strings_from_file("lua-valid-fixtures.txt")
local number_of_expressions = #expressions

regex_railroad.view_expression(expressions[math.random(1, number_of_expressions)][1], "lua")
local start_time = vim.fn.reltime()
-- require("plenary.profile").start("profile.log", {flame = true})
-- require("plenary.profile").stop()
require("plenary.profile").start("profile.log", { flame = true })
for _ = 1, 1000 do
  regex_railroad.view_expression(expressions[math.random(1, number_of_expressions)][1], "lua")
  -- regex_railroad.view_expression('()(a*123)[a-zA-Z%a]*', 'lua')
  -- vim.cmd("redraw!")
end
require("plenary.profile").stop()
print(vim.fn.reltimefloat(vim.fn.reltime(start_time)))
-- on my machine, this takes 0.3-0.4 seconds
-- however, it is very possible that lpeg and lulpeg cache results or something, probably need to be careful with these numbers
