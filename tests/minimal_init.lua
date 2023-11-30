vim.opt.rtp:append(".")

vim.opt.rtp:append("deps/LuLPeg")
vim.opt.rtp:append("deps/nui.nvim")

if #vim.api.nvim_list_uis() == 0 then
  vim.opt.rtp:append("deps/mini.nvim")
  require("mini.test").setup()
end
