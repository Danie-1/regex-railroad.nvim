local M = {}

local simple_components = require("regex-railroad.renderers.railroad.simple-components")
local compute_padding = require("regex-railroad.renderers.railroad.padding").compute_padding

---@param expression Expression
---@return RectangleOfCharacters
local function render_expression(expression)
  if #expression == 0 then
    return M.render({ type = "anchor", description = "EMPTY" })
  end
  -- assert(#expression > 0, "Expression must not be empty.")
  local rectangle = M.render(expression[1])
  for i = 2, #expression do
    local padding = compute_padding(expression[i - 1], expression[i])
    for _ = 1, padding do
      rectangle:push_railroad_col_right()
    end
    rectangle:concat_rectangle_right(M.render(expression[i]))
  end
  rectangle:push_railroad_col_left()
  rectangle:push_railroad_col_right()
  return rectangle
end

---@param item Expression|ExpressionComponent
---@return RectangleOfCharacters
function M.render(item)
  if item.type == "expression" then
    ---@cast item Expression
    return render_expression(item)
  elseif item.type == "anchor" then
    ---@cast item Anchor
    return simple_components.render_anchor(item)
  elseif item.type == "balanced_string" then
    ---@cast item BalancedString
    return simple_components.render_balanced_string(item)
  elseif item.type == "character" then
    ---@cast item Character
    return simple_components.render_character(item)
  elseif item.type == "character_class" then
    ---@cast item CharacterClass
    return simple_components.render_character_class(item)
  elseif item.type == "character_set" then
    ---@cast item CharacterSet
    local character_set = require("regex-railroad.renderers.railroad.character-set")
    return character_set.render_character_set(item)
  elseif item.type == "match_capture" then
    ---@cast item MatchCapture
    return simple_components.render_match_capture(item)
  elseif item.type == "group" then
    ---@cast item Group
    local capture_group = require("regex-railroad.renderers.railroad.capture-group")
    return capture_group.render_capture_group(item)
  elseif item.type == "position_capture" then
    ---@cast item PositionCapture
    return simple_components.render_position_capture(item)
  elseif item.type == "quantified_expression" then
    ---@cast item QuantifiedExpression
    local quantified_expressions = require("regex-railroad.renderers.railroad.quantified-expression")
    return quantified_expressions.render_quantifier(item)
  end
  error("Unrecognised expression type (please send a bug report).")
end

return M
