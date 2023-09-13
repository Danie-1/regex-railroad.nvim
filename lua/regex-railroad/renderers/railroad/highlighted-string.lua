---@class HighlightedString
---@field text string
---@field highlight string?

local HighlightedString = {}

---@param text string
---@param highlight string?
---@return HighlightedString
function HighlightedString:new(text, highlight)
  local new_highlighted_string = { text = text, highlight = highlight }
  self.__index = self
  return setmetatable(new_highlighted_string, self)
end

---@return integer
function HighlightedString:visible_length()
  return vim.fn.strchars(self.text)
end

return HighlightedString
