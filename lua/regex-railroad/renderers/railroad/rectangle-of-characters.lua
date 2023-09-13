local Deque = require("regex-railroad.deque")
local HighlightedString = require("regex-railroad.renderers.railroad.highlighted-string")
local config = require("regex-railroad").config
local railroad_characters = config.railroad_characters

---@class HighlightingSpec
---@field highlight string
---@field line integer
---@field col_start integer
---@field col_end integer

---@param highlighted_strings Deque
---@return integer
local function get_total_length(highlighted_strings)
  local total = 0
  for highlighted_string in highlighted_strings:iter() do
    total = total + highlighted_string:visible_length()
  end
  return total
end

--- Represents a rectangle of highlighted characters.
--- The main rail must be at index 0.
---@class RectangleOfCharacters: Deque
---@field height integer?
---@field width integer?
---@field [integer] Deque
local RectangleOfCharacters = Deque:new()

---@param rail_row Deque?
---@return RectangleOfCharacters
function RectangleOfCharacters:new(rail_row)
  if rail_row then
    local new_rectangle = RectangleOfCharacters:new()
    new_rectangle:push_row_top(rail_row)
    return new_rectangle
  else
    local new_rectangle = Deque:new()
    self.__index = self
    ---@cast new_rectangle RectangleOfCharacters
    return setmetatable(new_rectangle, self)
  end
end

---@protected
---@param row Deque
function RectangleOfCharacters:check_new_row(row)
  if self.width then
    assert(self.width == get_total_length(row), "New row must have same length as self.width!")
    self.height = self.height + 1
  else
    self.height = 1
    self.width = get_total_length(row)
  end
end

---@protected
---@param col Deque
function RectangleOfCharacters:check_new_col(col)
  if self.height then
    assert(self.front == col.front and self.back == col.back, "New col must have same front and back values")
    self.width = self.width + 1
  else
    self.height = col.front - col.back + 1
    self.width = 1
  end
  for line in col:iter() do
    assert(line:visible_length() == 1)
  end
end

---@param row Deque
function RectangleOfCharacters:push_row_top(row)
  self:check_new_row(row)
  self:push_front(row)
end

---@param row Deque
function RectangleOfCharacters:push_row_bottom(row)
  self:check_new_row(row)
  self:push_back(row)
end

---@protected
---@return Deque
function RectangleOfCharacters:create_blank_row()
  ---@type HighlightedString
  local text = HighlightedString:new(string.rep(" ", self.width))
  local blank_row = Deque:new()
  blank_row:push_front(text)
  return blank_row
end

---@param new_width integer
---@param extend_railroad boolean
function RectangleOfCharacters:extend_width_centrally(new_width, extend_railroad)
  assert(new_width >= self.width, "New width must be at least current width.")
  local difference = new_width - self.width
  local push_left = math.floor(difference / 2)
  local push_right = difference - push_left
  for _ = 1, push_left do
    self:push_blank_col_left(extend_railroad)
  end
  for _ = 1, push_right do
    self:push_blank_col_right(extend_railroad)
  end
end

---@protected
---@param row Deque
---@param extend_railroad boolean
function RectangleOfCharacters:prepare_for_centred_row(row, extend_railroad)
  local row_width = get_total_length(row)
  if row_width > self.width then
    self:extend_width_centrally(row_width, extend_railroad)
  else
    local difference = self.width - row_width
    local push_left = math.floor(difference / 2)
    local push_right = difference - push_left
    row:push_front(HighlightedString:new(string.rep(" ", push_left)))
    row:push_back(HighlightedString:new(string.rep(" ", push_right)))
  end
end

---@param row Deque
---@param extend_railroad boolean
function RectangleOfCharacters:push_centred_row_top(row, extend_railroad)
  self:prepare_for_centred_row(row, extend_railroad)
  self:push_row_top(row)
end

---@param row Deque
---@param extend_railroad boolean
function RectangleOfCharacters:push_centred_row_bottom(row, extend_railroad)
  self:prepare_for_centred_row(row, extend_railroad)
  self:push_row_bottom(row)
end

---@protected
function RectangleOfCharacters:assert_nonzero_width()
  assert(self.width, "Rectangle must have non-zero width!")
end

function RectangleOfCharacters:push_blank_row_bottom()
  self:assert_nonzero_width()
  self:push_row_bottom(self:create_blank_row())
end

function RectangleOfCharacters:push_blank_row_top()
  self:assert_nonzero_width()
  self:push_row_top(self:create_blank_row())
end

---@protected
---@return Deque
function RectangleOfCharacters:create_blank_railroad_col()
  local callback = function(line_num)
    return HighlightedString:new(line_num == 0 and railroad_characters.left_right or " ")
  end
  return self:create_new_col_using(callback)
end

---@protected
---@param extend_railroad boolean
---@return Deque
function RectangleOfCharacters:create_blank_col(extend_railroad)
  local callback = function(line_num)
    if line_num == 0 then
      return extend_railroad and HighlightedString:new(railroad_characters.left_right) or HighlightedString:new(" ")
    else
      return HighlightedString:new(" ")
    end
  end
  return self:create_new_col_using(callback)
end

---@protected
function RectangleOfCharacters:assert_nonzero_height()
  assert(self.height, "Rectangle must have non-zero height!")
end

function RectangleOfCharacters:push_railroad_col_left()
  self:assert_nonzero_height()
  self:push_col_left(self:create_blank_railroad_col())
end

function RectangleOfCharacters:push_railroad_col_right()
  self:assert_nonzero_height()
  self:push_col_right(self:create_blank_railroad_col())
end

---@param extend_railroad boolean
function RectangleOfCharacters:push_blank_col_left(extend_railroad)
  self:assert_nonzero_height()
  self:push_col_left(self:create_blank_col(extend_railroad))
end

---@param extend_railroad boolean
function RectangleOfCharacters:push_blank_col_right(extend_railroad)
  self:assert_nonzero_height()
  self:push_col_right(self:create_blank_col(extend_railroad))
end

---@param col Deque
function RectangleOfCharacters:push_col_left(col)
  self:check_new_col(col)
  for i in self:iter_indexes() do
    self[i]:push_front(col[i])
  end
end

---@param col Deque
function RectangleOfCharacters:push_col_right(col)
  self:check_new_col(col)
  for i in self:iter_indexes() do
    self[i]:push_back(col[i])
  end
end

---@protected
---@param new_front integer
---@param new_back integer
function RectangleOfCharacters:grow_height_to(new_front, new_back)
  assert(new_front >= self.front, "new_front must be at least self.front")
  assert(new_back <= self.back, "new_back must be at least self.front")
  for _ = 1, (new_front - self.front) do
    self:push_blank_row_top()
  end
  for _ = 1, (self.back - new_back) do
    self:push_blank_row_bottom()
  end
end

---@param other RectangleOfCharacters
function RectangleOfCharacters:concat_rectangle_right(other)
  local new_front = math.max(self.front, other.front)
  local new_back = math.min(self.back, other.back)
  self:grow_height_to(new_front, new_back)
  other:grow_height_to(new_front, new_back)
  for line_number = new_back, new_front do
    self[line_number]:extend_back(other[line_number])
  end
  self.width = self.width + other.width
end

--- Generates a new column to be used with push_col_<left/right>.
--- The callback will receive line number as input, and should return
--- a HighlightedString of length 1. The input will be zero on the rail
--- line, positive above it and negative below it.
---@param callback function(integer): HighlightedString
---@return Deque
function RectangleOfCharacters:create_new_col_using(callback)
  local column = Deque:new(callback(0))
  for line_num = 1, self.front do
    column:push_front(callback(line_num))
  end
  for line_num = -1, self.back, -1 do
    column:push_back(callback(line_num))
  end
  return column
end

---@param highlight string?
function RectangleOfCharacters:surround_with_box(highlight)
  local left_callback = function(_)
    return HighlightedString:new(railroad_characters.block.left, highlight)
  end
  local right_callback = function(_)
    return HighlightedString:new(railroad_characters.block.right, highlight)
  end
  local left_column = self:create_new_col_using(left_callback)
  local right_column = self:create_new_col_using(right_callback)
  self:push_col_left(left_column)
  self:push_col_right(right_column)
  local top_row = HighlightedString:new(string.rep(railroad_characters.block.top, self.width), highlight)
  local bottom_row = HighlightedString:new(string.rep(railroad_characters.block.bottom, self.width), highlight)
  self:push_row_top(Deque:new(top_row))
  self:push_row_bottom(Deque:new(bottom_row))
end

---@private
---@return string[], HighlightingSpec
function RectangleOfCharacters:generate_string_and_highlights()
  local lines = {}
  local highlights = {}
  local line_number = 0
  for line in self:iter() do
    local line_string = ""
    local col_number = 0
    for highlighted_text in line:iter() do
      line_string = line_string .. highlighted_text.text
      if highlighted_text.highlight then
        table.insert(highlights, {
          highlight = highlighted_text.highlight,
          line = line_number,
          col_start = col_number,
          col_end = col_number + highlighted_text.text:len(),
        })
      end
      col_number = col_number + highlighted_text.text:len()
    end
    table.insert(lines, line_string)
    line_number = line_number + 1
  end
  return lines, highlights
end

---@return string
function RectangleOfCharacters:debug_string()
  local lines, _ = self:generate_string_and_highlights()
  local output_string = ""
  for _, line in ipairs(lines) do
    output_string = output_string .. line .. "\n"
  end
  return output_string
end

---@param bufnr integer
---@return nil
function RectangleOfCharacters:render_to_buffer(bufnr)
  local lines, highlights = self:generate_string_and_highlights()
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      highlight.highlight,
      highlight.line,
      highlight.col_start,
      highlight.col_end
    )
  end
end

return RectangleOfCharacters
