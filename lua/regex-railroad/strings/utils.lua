local M = {}

---@param node_types string[]
---@return TSNode
function M.get_node_of_type_at_cursor(node_types)
  local types = {}
  for _, type in pairs(node_types) do
    types[type] = true
  end
  -- I'm not sure that this root_tree:parse thing is the right way to do things, but I can't get anything else to work
  local root_tree = vim.treesitter.get_parser()
  root_tree:parse()
  local node = vim.treesitter.get_node()
  for _ = 1, 10 do
    if node == nil then
      error("Failed to find appropriate node")
    end
    if types[node:type()] then
      return node
    end
    node = node:parent()
  end
  error("Failed to find appropriate node")
end

---@param node TSNode
---@return string
function M.get_node_text(node)
  return vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
end

return M
