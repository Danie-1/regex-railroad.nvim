local M = {}

local config = require("regex-railroad").config
local highlights = config.highlights
local railroad_characters = config.railroad_characters
local HighlightedString = require("regex-railroad.renderers.railroad.highlighted-string")
local RectangleOfCharacters = require("regex-railroad.renderers.railroad.rectangle-of-characters")
local Deque = require("regex-railroad.deque")

---@param item CharacterSetItem
---@return RectangleOfCharacters
local function render_item(item)
  if type(item) == "string" then
    return RectangleOfCharacters:new(Deque:new(HighlightedString:new(item, highlights.character)))
  elseif item.type == "character_class" then
    ---@cast item CharacterClass
    return RectangleOfCharacters:new(
      Deque:new(HighlightedString:new(item.class:upper():gsub("_", " "), highlights.character_class))
    )
  elseif item.type == "character_range" then
    ---@cast item CharacterRange
    return RectangleOfCharacters:new(
      Deque:new(HighlightedString:new(item.start .. "-" .. item.finish, highlights.character_set))
    )
  end
  error("Unexpected bug, please report.")
end

---@param items CharacterSetItem[]
---@return RectangleOfCharacters[], integer
local function render_and_get_widest(items)
  local widest = 0
  ---@type RectangleOfCharacters[]
  local rendered_items = {}
  for _, item in ipairs(items) do
    local rendered_item = render_item(item)
    table.insert(rendered_items, rendered_item)
    widest = math.max(widest, rendered_item.width)
  end
  return rendered_items, widest
end

---@param rendered_items RectangleOfCharacters[]
---@param widest integer
---@return nil
local function extend_all_to_width(rendered_items, widest)
  for _, item in ipairs(rendered_items) do
    item:extend_width_centrally(widest, true)
  end
end

---@param rendered_items RectangleOfCharacters[]
---@return Deque[], { [integer]: true }
local function concatenate_and_get_railroad_line_nums(rendered_items)
  local lines = {}
  ---@type { [integer]: true }
  local railroad_line_numbers = {}
  for _, item in ipairs(rendered_items) do
    for line_num in item:iter_indexes() do
      table.insert(lines, item[line_num])
      if line_num == 0 then
        railroad_line_numbers[#lines] = true
      end
    end
  end
  return lines, railroad_line_numbers
end

---@param line_nums { [integer]: true }
---@return integer, integer
local function get_highest_and_lowest_line_nums(line_nums)
  local lowest
  local highest
  for num, _ in pairs(line_nums) do
    lowest = lowest == nil and num or math.min(lowest, num)
    highest = highest == nil and num or math.max(highest, num)
  end
  return lowest, highest
end

---@param lines Deque[]
---@param line_nums { [integer]: true }
---@param middle integer
local function add_side_bar_to_lines(lines, line_nums, middle)
  local lowest, highest = get_highest_and_lowest_line_nums(line_nums)
  for i, line in ipairs(lines) do
    local left_char
    local right_char
    if i > highest or i < lowest then
      left_char = " "
      right_char = " "
    elseif i == highest and i == lowest then
      left_char = railroad_characters.left_right
      right_char = railroad_characters.left_right
    elseif i == highest and i == middle then
      left_char = railroad_characters.up_left_right
      right_char = railroad_characters.up_left_right
    elseif i == lowest and i == middle then
      left_char = railroad_characters.down_left_right
      right_char = railroad_characters.down_left_right
    elseif i == highest then
      left_char = railroad_characters.up_right
      right_char = railroad_characters.up_left
    elseif i == lowest then
      left_char = railroad_characters.down_right
      right_char = railroad_characters.down_left
    elseif i == middle and line_nums[i] then
      left_char = railroad_characters.up_down_left_right
      right_char = railroad_characters.up_down_left_right
    elseif i == middle then
      left_char = railroad_characters.up_down_left
      right_char = railroad_characters.up_down_right
    elseif line_nums[i] then
      left_char = railroad_characters.up_down_right
      right_char = railroad_characters.up_down_left
    else
      left_char = railroad_characters.up_down
      right_char = railroad_characters.up_down
    end
    line:push_front(HighlightedString:new(left_char, highlights.railroad))
    line:push_back(HighlightedString:new(right_char, highlights.railroad))
  end
end

---@param lines Deque[]
---@param middle integer
---@return RectangleOfCharacters
local function create_rectangle_of_characters_with_rail_at(lines, middle)
  local rectangle = RectangleOfCharacters:new()
  for i = middle, 1, -1 do
    rectangle:push_row_top(lines[i])
  end
  for i = middle + 1, #lines do
    rectangle:push_row_bottom(lines[i])
  end
  return rectangle
end

---@param character_set CharacterSet
---@return RectangleOfCharacters
function M.render_character_set(character_set)
  local rendered_items, widest = render_and_get_widest(character_set.items)
  extend_all_to_width(rendered_items, widest)
  local lines, railroad_line_numbers = concatenate_and_get_railroad_line_nums(rendered_items)
  local middle = math.ceil(#lines / 2)
  add_side_bar_to_lines(lines, railroad_line_numbers, middle)
  local rectangle = create_rectangle_of_characters_with_rail_at(lines, middle)
  rectangle:push_centred_row_top(Deque:new(HighlightedString:new("OF")), true)
  rectangle:push_centred_row_top(
    Deque:new(HighlightedString:new(character_set.complement == "true" and "NONE" or "ANY")),
    true
  )
  return rectangle
end

return M
