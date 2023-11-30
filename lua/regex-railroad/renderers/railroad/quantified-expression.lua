local M = {}

local main_renderer = require("regex-railroad.renderers.railroad")
local config = require("regex-railroad").config
local highlights = config.highlights
local railroad_characters = config.railroad_characters
local HighlightedString = require("regex-railroad.renderers.railroad.highlighted-string")
local string_utils = require("regex-railroad.renderers.railroad.string-utils")

---@param render_top boolean
---@param render_bottom boolean
---@return string
local function get_junction_char(render_top, render_bottom)
  local junction_char
  if render_top and render_bottom then
    junction_char = railroad_characters.up_down_left_right
  elseif render_top then
    junction_char = railroad_characters.up_left_right
  elseif render_bottom then
    junction_char = railroad_characters.down_left_right
  else
    junction_char = ""
  end
  return junction_char
end

---@param rendered_expr RectangleOfCharacters
---@param render_top boolean
---@param render_bottom boolean
---@return Deque
local function construct_column(rendered_expr, render_top, render_bottom, junction_char)
  local top_character = render_top and railroad_characters.up_down or " "
  local bottom_character = render_bottom and railroad_characters.up_down or " "
  local callback = function(line_number)
    return HighlightedString:new(
      line_number == 0 and junction_char or line_number > 0 and top_character or line_number < 0 and bottom_character,
      highlights.railroad
    )
  end
  return rendered_expr:create_new_col_using(callback)
end

---@param rendered_expr RectangleOfCharacters
---@return nil
local function draw_top_path(rendered_expr)
  local top_path = HighlightedString:new(
    railroad_characters.down_right
      .. string_utils.pad_string(
        railroad_characters.arrow_right,
        rendered_expr.width - 2,
        railroad_characters.left_right,
        "center"
      )
      .. railroad_characters.down_left,
    highlights.railroad
  )
  rendered_expr:push_row_top(Deque:new(top_path))
end

---@param min_repeat integer
---@param max_repeat integer?
---@return string
local function get_repeat_label(min_repeat, max_repeat)
  if min_repeat <= 1 and (max_repeat == math.huge or max_repeat <= 2) then
    return ""
  elseif min_repeat <= 1 then
    return "≤" .. max_repeat .. "x"
  elseif max_repeat == nil then
    return "≥" .. min_repeat .. "x"
  elseif max_repeat == min_repeat then
    return min_repeat .. "x"
  else
    return min_repeat .. "-" .. max_repeat .. "x"
  end
end

---@param rendered_expr RectangleOfCharacters
---@param min_repeat integer
---@param max_repeat integer?
---@param greedy 'true'|'false'
---@return string, string?, string?
local function get_bottom_label(rendered_expr, min_repeat, max_repeat, greedy)
  local repeat_label = get_repeat_label(min_repeat, max_repeat)
  local greedy_label = greedy ~= "" and greedy or nil
  local label_1
  local label_2
  local label_3
  if greedy_label == nil and rendered_expr.width > repeat_label:len() + 4 then
    label_1 = railroad_characters.arrow_left .. " " .. repeat_label .. " " .. railroad_characters.arrow_left
  elseif greedy_label ~= nil and rendered_expr.width > repeat_label:len() + greedy_label:len() + 5 then
    label_1 = railroad_characters.arrow_left
      .. " "
      .. repeat_label
      .. (repeat_label == "" and "" or " ")
      .. greedy_label
      .. " "
      .. railroad_characters.arrow_left
  elseif rendered_expr.width > repeat_label:len() + 4 and repeat_label ~= "" then
    label_1 = railroad_characters.arrow_left .. " " .. repeat_label .. " " .. railroad_characters.arrow_left
    label_2 = greedy_label
  elseif repeat_label ~= "" then
    label_1 = railroad_characters.arrow_left
    label_2 = repeat_label
    label_3 = greedy_label
  else
    label_1 = railroad_characters.arrow_left
    label_2 = greedy_label
  end
  return label_1, label_2, label_3
end

---@param quantified_expression QuantifiedExpression
---@return RectangleOfCharacters
function M.render_quantifier(quantified_expression)
  if quantified_expression.max == nil then
    quantified_expression.max = quantified_expression.min
  end
  local rendered_expr = main_renderer.render(quantified_expression.sub_expr)
  local min_repeat = tonumber(quantified_expression.min) ---@cast min_repeat integer
  local max_repeat = tonumber(quantified_expression.max) ---@cast min_repeat integer
  local render_top = min_repeat == 0
  local render_bottom = max_repeat > 1

  local junction_char = get_junction_char(render_top, render_bottom)
  if junction_char == "" then
    return rendered_expr
  end
  local column = construct_column(rendered_expr, render_top, render_bottom, junction_char)
  rendered_expr:push_col_left(column)
  rendered_expr:push_col_right(column)

  if render_top then
    draw_top_path(rendered_expr)
  end

  local label_1, label_2, label_3 =
    get_bottom_label(rendered_expr, min_repeat, max_repeat, quantified_expression.greedy)
  if render_bottom then
    local bottom_path = HighlightedString:new(
      railroad_characters.up_right
        .. string_utils.pad_string(label_1, rendered_expr.width - 2, railroad_characters.left_right, "center")
        .. railroad_characters.up_left,
      highlights.railroad
    )
    rendered_expr:push_row_bottom(Deque:new(bottom_path))
  end
  if label_2 then
    rendered_expr:push_centred_row_bottom(Deque:new(HighlightedString:new(label_2)), true)
  end
  if label_3 then
    rendered_expr:push_centred_row_bottom(Deque:new(HighlightedString:new(label_3)), true)
  end
  return rendered_expr
end

return M
