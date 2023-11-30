-- local success, _ = pcall(require, "lpeg")
-- local lpeg = success and require("lpeg") or require("lulpeg")
vim.opt.rtp:append("/home/daniel/projects/regex-railroad.nvim/deps/LuLPeg")
local lpeg = require("lulpeg")

return lpeg
