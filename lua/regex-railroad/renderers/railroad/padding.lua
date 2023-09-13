local M = {}

---@param expression_1 ExpressionComponent
---@param expression_2 ExpressionComponent
---@return integer
function M.compute_padding(expression_1, expression_2)
  if expression_1.type == "character" and expression_2.type == "character" then
    return 0
  end
  return 1
end

return M
