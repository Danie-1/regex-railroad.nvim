local M = {}

M.grammar = {}

local g = M.grammar

local lpeg = require("regex-railroad.lpeg")

local groups_assigned_array = {}

function M.get_group_number(_, i)
  local group_number = 1
  while groups_assigned_array[tostring(group_number)] and i > groups_assigned_array[tostring(group_number)] do
    group_number = group_number + 1
  end
  groups_assigned_array[tostring(group_number)] = i
  return i, tostring(group_number)
end

function M.register_named_group(_, i, start, name, finish)
  if groups_assigned_array[name] and groups_assigned_array[name] ~= i then
    error({
      message = "Named group '" .. name .. "' already exists:",
      start = start - 1,
      finish = finish - 1,
    })
  end
  groups_assigned_array[name] = i
  return i, name
end

function M.reset()
  groups_assigned_array = {}
end

--- Returns an expression that matches the empty string,
--- but captures "type" with key "type". (See examples elsewhere)
---@param type string
function M.capture_type(type)
  return lpeg.Cg(lpeg.P("") / type, "type")
end

--- If pattern matches, raise an error with message.
--- To include position information, capture a start and
--- finish position in pattern.
---@param pattern Pattern
---@param message string
function M.parsing_error_if(pattern, message)
  local function callback(_, _, start, finish)
    error({ message = message, start = start - 1, finish = finish - 1 })
  end
  return lpeg.Cmt(pattern, callback)
end

function M.ensure_group_already_exists(_, _, group_name)
  if groups_assigned_array[group_name] then
    return true
  else
    return false
  end
end

local capture_type = M.capture_type

-- https://stackoverflow.com/questions/39006753/matching-unicode-punctuation-using-lpeg
-- It would probably be better to use lpeg.utfR,
-- but on my machine it isn't available for some reason.
-- Anyway, hopefully this works.
local cont = lpeg.R("\128\191") -- continuation byte
local utf8character = lpeg.R("\0\127")
    + lpeg.R("\194\223") * cont
    + lpeg.R("\224\239") * cont * cont
    + lpeg.R("\240\244") * cont * cont * cont

g.sub_expr = lpeg.V("choice") + lpeg.V("choiceless") + lpeg.P("")

g.choice = lpeg.Ct(capture_type("choice") * lpeg.C(lpeg.V("choiceless")) *
  (lpeg.P("|") * lpeg.C(lpeg.V("choiceless"))) ^ 1)

g.choiceless = lpeg.V("component") ^ 1

g.component = lpeg.V("quantified") + lpeg.V("unquantified")

g.quantified = lpeg.Ct(
  capture_type("quantified_expression")
  * lpeg.Cg(lpeg.Ct(capture_type("expression") * lpeg.V("unquantified")), "sub_expr")
  * lpeg.V("quantifier")
)

g.quantifier = lpeg.V("quantifier_repeat") * lpeg.V("quantifier_greediness")

---@param pattern string
---@param min string
---@param max string
local function quantifier_repeat(pattern, min, max)
  return lpeg.P(pattern) * lpeg.Cg(lpeg.P("") / min, "min") * lpeg.Cg(lpeg.P("") / max, "max")
end

g.quantifier_repeat = quantifier_repeat("?", "0", "1")
    + quantifier_repeat("*", "0", "Infinity")
    + quantifier_repeat("+", "1", "Infinity")
    + (
      lpeg.P("{")
      * (
        lpeg.Cg(lpeg.R("09") ^ 1, "min")
        * (lpeg.P(",") * lpeg.Cg(lpeg.R("09") ^ 1 + lpeg.P("") / "Infinity", "max")) ^ -1
      )
      * lpeg.P("}")
    )

g.quantifier_greediness = lpeg.Cg(lpeg.P("?") / "lazy"
  + lpeg.P("+") / "possessive"
  + lpeg.P("") / "greedy", "greediness")

g.fail_if_open_bracket = M.parsing_error_if(lpeg.Cp() * lpeg.P("(") * lpeg.Cp(), "Bracket is never closed:")

g.fail_if_close_bracket = M.parsing_error_if(lpeg.Cp() * lpeg.P(")") * lpeg.Cp(), "Bracket is never opened:")

g.fail_if_open_square_bracket = M.parsing_error_if(lpeg.Cp() * lpeg.P("[") * lpeg.Cp(), "Set is never closed:")

g.anchor_no_quantifier = M.parsing_error_if(
  lpeg.Cp() * lpeg.V("anchor") * lpeg.V("quantifier") * lpeg.Cp(),
  "Anchor expressions cannot be quantified:"
) + lpeg.V("anchor")

g.assert_no_quantifier = M.parsing_error_if(
  lpeg.Cp() * lpeg.V("quantifier") * lpeg.Cp(),
  "Quantifier is at an invalid location:"
)

g.signed_number = lpeg.P("-") ^ -1 * lpeg.R("09") ^ 1

g.valid_group_name = (lpeg.R("az", "AZ", "__") * lpeg.R("09", "az", "AZ", "__") ^ -31)

g.numbered_group = lpeg.Ct(
  lpeg.P("(")
  * (-lpeg.P("?"))
  * M.capture_type("group")
  * lpeg.Cg(lpeg.Cmt(lpeg.P(""), M.get_group_number) / "Group %1", "name")
  * lpeg.Cg(lpeg.Ct(M.capture_type("expression") * lpeg.V("sub_expr")), "sub_expr")
  * lpeg.P(")")
)

g.invalid_character_in_group_name = M.parsing_error_if(
  lpeg.Cp() * lpeg.P(1) * lpeg.Cp(),
  "Invalid character in group name:"
)

g.fail_if_unrecognised_group_type = M.parsing_error_if(
  lpeg.P("(?") * lpeg.Cp() * lpeg.P(1) * lpeg.Cp(),
  "Unrecognised group type:"
)

g.escaped_character = lpeg.P("\\") + lpeg.Ct(
  capture_type("character") * lpeg.Cg(lpeg.P(1) - lpeg.R("az", "AZ", "09"), "character")
)

g.pcre_q_e_sequence = lpeg.P("\\Q") * (lpeg.P(1) - lpeg.P("\\E")) ^ 0 * lpeg.P("\\E")

g.character_set = lpeg.P("[")
    * lpeg.Ct(
      capture_type("character_set")
      * lpeg.Cg(lpeg.P("^") / "true", "complement") ^ -1
      * lpeg.Cg(lpeg.Ct(lpeg.V("character_set_items")), "items")
    )
    * lpeg.P("]")
    + lpeg.V("fail_if_open_square_bracket")

g.character_set_items = (lpeg.C(lpeg.P("]")) + lpeg.V("character_set_item"))
    * (lpeg.V("character_set_item") - lpeg.P("]")) ^ 0

g.character_set_item = (lpeg.V("literal_character") - (lpeg.P("-") + lpeg.P(1) * lpeg.P("-")))
    + lpeg.V("character_range")

g.character_range = lpeg.Ct(
  M.capture_type("character_range")
  * lpeg.Cg(lpeg.V("literal_character") / "%0", "start")
  * lpeg.P("-")
  * lpeg.Cg(utf8character - lpeg.S("\\]-"), "finish")
)

g.invalid_characters = lpeg.V("never_match")

g.meta_characters = lpeg.S("\\^$.[|()?*+")

g.literal_character = lpeg.Ct(
  capture_type("character")
  * lpeg.Cg(utf8character - lpeg.V("meta_characters"), "character")
)

g.never_match = lpeg.P("") - lpeg.P("")

g.start_of_string_anchor = lpeg.P("^") / "START OF STRING"

g.end_of_string_anchor = lpeg.P("$") / "END OF STRING"

g.anchor = lpeg.Ct(capture_type("anchor") * lpeg.Cg(g.start_of_string_anchor + g.end_of_string_anchor, "description"))

g.any_character = lpeg.Ct(capture_type("character_class") * lpeg.Cg(lpeg.P(".") / "any_character", "class"))

return M
