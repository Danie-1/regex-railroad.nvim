local M = {}

---@param text string
---@param desired_length integer
---@param pad_character char
---@param align 'center'|'right'|'left'
---@return string
function M.pad_string(text, desired_length, pad_character, align)
  local current_length = vim.fn.strchars(text)
  assert(current_length <= desired_length, "current_length must be at most desired_length")
  local difference = desired_length - current_length
  if align == "center" then
    local push_left = math.floor(difference / 2)
    local push_right = difference - push_left
    return string.rep(pad_character, push_left) .. text .. string.rep(pad_character, push_right)
  elseif align == "right" then
    return string.rep(pad_character, difference) .. text
  elseif align == "left" then
    return text .. string.rep(pad_character, difference)
  end
  error("This is a bug. Please report.")
end

return M
