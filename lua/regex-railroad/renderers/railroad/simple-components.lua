local M = {}

local Deque = require("regex-railroad.deque")
local HighlightedString = require("regex-railroad.renderers.railroad.highlighted-string")
local RectangleOfCharacters = require("regex-railroad.renderers.railroad.rectangle-of-characters")
local config = require("regex-railroad").config
local highlights = config.highlights
local string_utils = require("regex-railroad.renderers.railroad.string-utils")

---@param text string
---@param sep string # should be a single character
---@return string[]
local function split_string_at_sep(text, sep)
  local lines = {}
  for line in string.gmatch(text .. sep, "[^" .. sep .. "]*" .. sep) do
    table.insert(lines, line:sub(1, #line - 1))
  end
  return lines
end

---@param lines string[]
---@param highlight string?
---@return RectangleOfCharacters
local function boxed_lines(lines, highlight)
  local rectangle = RectangleOfCharacters:new()
  local middle = math.floor(#lines / 2) + 1
  local max_length = 0
  for _, line in ipairs(lines) do
    max_length = math.max(max_length, line:len())
  end
  for i = middle, 1, -1 do
    rectangle:push_row_top(
      Deque:new(HighlightedString:new(string_utils.pad_string(lines[i], max_length, " ", "center"), highlight))
    )
  end
  for i = middle + 1, #lines do
    rectangle:push_row_bottom(
      Deque:new(HighlightedString:new(string_utils.pad_string(lines[i], max_length, " ", "center"), highlight))
    )
  end
  rectangle:surround_with_box(highlight)
  return rectangle
end

---@param anchor Anchor
---@return RectangleOfCharacters
function M.render_anchor(anchor)
  local lines = split_string_at_sep(anchor.description, " ")
  return boxed_lines(lines, highlights.anchor)
end

---@param balanced_string BalancedString
---@return RectangleOfCharacters
function M.render_balanced_string(balanced_string)
  local rectangle = RectangleOfCharacters:new(
    Deque:new(HighlightedString:new(" open=" .. balanced_string.open, highlights.balanced_string))
  )
  rectangle:push_centred_row_top(Deque:new(HighlightedString:new("Balanced", highlights.balanced_string)), false)
  rectangle:push_centred_row_bottom(
    Deque:new(HighlightedString:new("close=" .. balanced_string.close, highlights.balanced_string)),
    false
  )
  rectangle:surround_with_box(highlights.balanced_string)
  return rectangle
end

---@param character Character
---@return RectangleOfCharacters
function M.render_character(character)
  return RectangleOfCharacters:new(Deque:new(HighlightedString:new(character.character, highlights.character)))
end

---@param character_class CharacterClass
---@return RectangleOfCharacters
function M.render_character_class(character_class)
  local lines = split_string_at_sep((character_class.negate and "NOT_" or "") .. character_class.class:upper(), "_")
  return boxed_lines(lines, highlights.character_class)
end

---@param match_capture MatchCapture
---@return RectangleOfCharacters
function M.render_match_capture(match_capture)
  return boxed_lines({ "Match", "group", match_capture.name }, highlights.match_capture)
end

---@param position_capture PositionCapture
---@return RectangleOfCharacters
function M.render_position_capture(position_capture)
  return boxed_lines({ "Position", "capture" }, highlights.position_capture)
end

return M
