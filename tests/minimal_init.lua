local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local is_not_a_directory = vim.fn.isdirectory(plenary_dir) == 0
if is_not_a_directory then
  vim.fn.system({ "git", "clone", "https://github.com/nvim-lua/plenary.nvim", plenary_dir })
end

-- LuLPeg is slower than LPeg but seems easier to install.
local lulpeg_dir = "/tmp/lulpeg"
if vim.fn.isdirectory(lulpeg_dir) == 0 then
  vim.fn.system({ "git", "clone", "https://github.com/pygy/LuLPeg", lulpeg_dir .. "/lua" })
end

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(lulpeg_dir)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
