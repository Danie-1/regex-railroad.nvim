local plugin = require("regex-railroad")

local function get_strings_from_file(language)
  local file = io.open("tests/regex-railroad/" .. language .. "/" .. language .. "-strings.txt")
  assert(file)
  return function()
    return file:read("*l")
  end
end

describe("lua", function()
  local renderer = require("regex-railroad.renderers.railroad")
  local parse_expression = require("regex-railroad.parse-expression").parse_expression
  for string in get_strings_from_file("lua") do
    it("should pass " .. string, function()
      local parsed_expression = parse_expression(string, "lua")
      local rendered = renderer.render(parsed_expression)
      print(vim.inspect(rendered))
      print(rendered:debug_string())
    end)
  end
end)
