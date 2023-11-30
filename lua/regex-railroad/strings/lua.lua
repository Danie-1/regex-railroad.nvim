local M = {}

local utils = require("regex-railroad.strings.utils")

---@param str string
---@return string
function M.unescape(str)
  local escape_sequences = {
    a = "\a",
    b = "\b",
    f = "\f",
    n = "\n",
    r = "\r",
    t = "\t",
    v = "\v",
    ["\\"] = "\\",
    ['"'] = '"',
    ["'"] = "'",
  }
  -- I'm not sure if this is worth doing, and I am not sure how to go about doing it
  -- local decode_digit_escape = function(match)
  --   assert(tonumber(match:sub(2)) < 256, "Escape sequence " .. match:sub(2) .. " too large.")
  --   return string.char(match:sub(2))
  -- end
  -- local escaped_digit_sequences = str:gsub("\\%d%d?%d?", decode_digit_escape)
  local fully_escaped = str:gsub("\\[abfnrtv\\\"']", function(match)
    return escape_sequences[match:sub(2)]
  end)
  return fully_escaped:sub(2, fully_escaped:len() - 1)
end

---@return string
function M.get_unescaped_string_at_cursor()
  local string_node = utils.get_node_of_type_at_cursor({ "string" })
  local string_node_text = vim.treesitter.get_node_text(string_node, vim.api.nvim_get_current_buf())
  return M.unescape(string_node_text)
end

return M
