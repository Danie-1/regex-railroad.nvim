local M = {}

local function get_parsers_folder()
  local path_of_this_file = debug.getinfo(1, "S").source:sub(2)
  local folder_of_this_file = path_of_this_file:match(".*[\\/]")
  return folder_of_this_file
end

-- "The `getinfo` function is not efficient." (https://www.lua.org/pil/23.1.html)
-- So we avoid executing it more than once.
local parsers_folder = get_parsers_folder()

--- Returns '' if the file doesn't exist
---@param file_name string
---@return string
local function read_file_if_exists(file_name)
  local file_reader = io.open(file_name)
  if file_reader then
    return file_reader:read("*all")
  else
    return ""
  end
end

--- Concatenates the contents of:
---  - grammar_name.peg
---  - grammar_name-character-classes.peg
---  - grammar_name-quantifiers.peg
--- and ignores any files that don't exist
---@param grammar_name string
---@return string
function M.read_grammar_file(grammar_name)
  local file_name_base = parsers_folder .. "grammars/" .. grammar_name
  local main_file = read_file_if_exists(file_name_base .. ".lpeg")
  local character_classes = read_file_if_exists(file_name_base .. "-escaped-chars.lpeg")
  local quantifiers = read_file_if_exists(file_name_base .. "-quantifiers.lpeg")
  return main_file .. character_classes .. quantifiers
end

return M
