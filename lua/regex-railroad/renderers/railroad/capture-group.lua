local M = {}

local main_renderer = require("regex-railroad.renderers.railroad")
local config = require("regex-railroad").config
local highlights = config.highlights
local box_characters = config.railroad_characters.capture_group_characters
local HighlightedString = require("regex-railroad.renderers.railroad.highlighted-string")
local string_utils = require("regex-railroad.renderers.railroad.string-utils")

---@param rendered_expr RectangleOfCharacters
---@return Deque
local function construct_column(rendered_expr)
  local callback = function(line_number)
    return HighlightedString:new(
      line_number == 0 and box_characters.vertical_through_rail or box_characters.vertical,
      highlights.capture_group
    )
  end
  return rendered_expr:create_new_col_using(callback)
end

---@param capture_group Group
---@return RectangleOfCharacters
function M.render_capture_group(capture_group)
  local rendered_expr = main_renderer.render(capture_group.sub_expr)
  local column = construct_column(rendered_expr)
  rendered_expr:push_col_left(column)
  rendered_expr:push_col_right(column)

  local bottom_part = HighlightedString:new(
    box_characters.bottom_left
      .. string.rep(box_characters.horizontal, rendered_expr.width - 2)
      .. box_characters.bottom_right,
    config.highlights.capture_group
  )
  rendered_expr:push_row_bottom(Deque:new(bottom_part))

  if capture_group.name == nil then
    local top_part = HighlightedString:new(
      box_characters.top_left
        .. string.rep(box_characters.horizontal, rendered_expr.width - 2)
        .. box_characters.top_right,
      highlights.capture_group
    )
    rendered_expr:push_row_top(Deque:new(top_part))
  elseif rendered_expr.width < capture_group.name:len() + 2 then
    local top_part = HighlightedString:new(
      box_characters.top_left
        .. string.rep(box_characters.horizontal, rendered_expr.width - 2)
        .. box_characters.top_right,
      highlights.capture_group
    )
    rendered_expr:push_row_top(Deque:new(top_part))
    rendered_expr:push_centred_row_top(Deque:new(HighlightedString:new(capture_group.name)), true)
  else
    local top_part = HighlightedString:new(
      box_characters.top_left
        .. string_utils.pad_string(capture_group.name, rendered_expr.width - 2, box_characters.horizontal, "center")
        .. box_characters.top_right,
      highlights.capture_group
    )
    rendered_expr:push_row_top(Deque:new(top_part))
  end

  return rendered_expr
end

return M
