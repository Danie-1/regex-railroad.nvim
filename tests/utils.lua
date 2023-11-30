local M = {}

function M.get_strings_from_file(file_name)
  local file = io.open("tests/fixtures/" .. file_name)
  assert(file)
  local output = {}
  local line = file:read("*l")
  while line do
    if line ~= "" and line:sub(1, 5) ~= "XFAIL" then
      table.insert(output, { line })
    end
    line = file:read("*l")
  end
  return output
end

function M.byteify(str)
  return string.gsub(str, ".", function(c)
    return tostring(string.byte(c))
  end)
end

function M.write_line_to_child(line, child)
  child.api.nvim_buf_set_lines(0, 0, 0, false, { line })
end

function M.new_screenshot_set(child)
  return MiniTest.new_set({
    hooks = {
      pre_case = function()
        child.restart({ "-u", "tests/minimal_init.lua" })
        child.bo.readonly = false
        child.lua([[
        M = require('regex-railroad')
        M.setup({ split_options = { size = "85%" }, clear = true })
      ]])
        child.o.lines, child.o.columns = 20, 60
        child.bo.readonly = false
      end,
    },
  })
end

M.flavours = { "lua", "python" }

return M
