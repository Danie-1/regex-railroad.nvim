---@class Deque
---@field front integer # denotes the index of the current front element
---@field back integer # denotes the index of the current back element
Deque = {}

---@return Deque
function Deque:new(first_item)
  if first_item then
    local new_deque = Deque:new()
    new_deque:push_front(first_item)
    return new_deque
  else
    local new_deque = { front = -1, back = 0 }
    self.__index = self
    return setmetatable(new_deque, self)
  end
end

---@param object table
---@return nil
function Deque:push_front(object)
  self.front = self.front + 1
  self[self.front] = object
end

---@param object table
---@return nil
function Deque:push_back(object)
  self.back = self.back - 1
  self[self.back] = object
end

function Deque:iter()
  local index_iterator = self:iter_indexes()
  return function()
    local i = index_iterator()
    if i then
      return self[i]
    end
  end
end

function Deque:iter_indexes()
  local i = self.front + 1
  return function()
    i = i - 1
    if i >= self.back then
      return i
    end
  end
end

---@param other Deque
---@return nil
function Deque:extend_back(other)
  for item in other:iter() do
    self:push_back(item)
  end
end

return Deque
