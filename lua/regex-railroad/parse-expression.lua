local M = {}

--- Parse a regular expression with specific flavour.
---@param expression string
---@param flavour string
---@return Expression
function M.parse_expression(expression, flavour)
  local re = require("regex-railroad.re")
  local read_grammar = require("regex-railroad.parsers.read-grammar-file")
  local grammar_file_contents = read_grammar.read_grammar_file(flavour)

  local current_group_number = 0
  local defs = {
    get_capture_number = function()
      current_group_number = current_group_number + 1
      return current_group_number
    end,
  }

  local grammar = re.compile(grammar_file_contents, defs)
  return grammar:match(expression)
end

return M
