local utils = dofile("tests/utils.lua")
local child = MiniTest.new_child_neovim()

local T = utils.new_screenshot_set(child)

for _, flavour in ipairs(utils.flavours) do
  T[flavour] = MiniTest.new_set({
    parametrize = utils.get_strings_from_file(flavour .. "-invalid-fixtures.txt"),
    data = { flavour = flavour },
  })

  T[flavour]["renders correctly"] = function(string)
    child.lua("M.view_expression([====[" .. string .. "]====], '" .. flavour .. "')")
    utils.write_line_to_child(string, child)
    MiniTest.expect.reference_screenshot(
      child.get_screenshot(),
      "tests/screenshots/" .. flavour .. "-invalid-" .. utils.byteify(string),
      { force = false }
    )
  end
end

return T
