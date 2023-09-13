local M = {}

local utils = require("regex-railroad.strings.utils")

---@return string
function M.get_unescaped_string_at_cursor()
  local string_node = utils.get_node_of_type_at_cursor({ "string" })
  local string_node_text = vim.treesitter.get_node_text(string_node, vim.api.nvim_get_current_buf())
  local child = string_node:child()
  local string_start = string_node:named_children()[1]
  local string_content = string_node:named_children()[2]
  local string_end = string_node:named_children()[3]
  local string_start_text = vim.treesitter.get_node_text(string_start, vim.api.nvim_get_current_buf())
  -- print(string_node_text)
  -- print(string_node_text .. ' ' .. string_start_text)
  assert(string_node_text:sub(1, 1):lower() == "r", "Only raw python strings are currently supported.")
  local string_content_text = utils.get_node_text(string_content)
  return string_content_text
end

return M
