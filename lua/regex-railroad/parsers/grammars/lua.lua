local M = {
  grammar = {},
}

local g = M.grammar

local base = require("regex-railroad.parsers.grammars.base")
local lpeg = require("regex-railroad.lpeg")

g[1] = "grammar"

g.grammar = lpeg.Ct(
  base.capture_type("expression")
  * lpeg.V("start_of_string_anchor") ^ -1
  * lpeg.V("sub_expr")
  * lpeg.V("end_of_string_anchor") ^ -1
  * (-lpeg.P(1))
)

g.start_of_string_anchor =
    lpeg.Ct(base.capture_type("anchor") * lpeg.Cg(base.grammar.start_of_string_anchor - lpeg.B(lpeg.P(1)), "description"))

g.end_of_string_anchor =
    lpeg.Ct(base.capture_type("anchor") * lpeg.Cg(base.grammar.end_of_string_anchor - lpeg.P(2), "description"))

g.sub_expr = (lpeg.V("component") - lpeg.V("end_of_string_anchor")) ^ 0

g.component = lpeg.V("quantified")
    + base.parsing_error_if(lpeg.Cp() * (lpeg.P("%") - lpeg.P(2)) * lpeg.Cp(), "Trailing escape character:")
    + lpeg.V("position_capture")
    + lpeg.V("group")
    + lpeg.V("fail_if_open_bracket")
    + lpeg.V("fail_if_close_bracket")
    + lpeg.V("match_numbered_capture")
    + lpeg.V("character_class")
    + lpeg.V("balanced_string")

g.match_numbered_capture = lpeg.Ct(
      base.capture_type("match_capture")
      * lpeg.P("%")
      * lpeg.Cg(lpeg.Cmt(lpeg.R("19"), base.ensure_group_already_exists), "name")
    )
    + base.parsing_error_if(lpeg.Cp() * lpeg.P("%0") * lpeg.Cp(), "0 is not a valid group index:")
    + base.parsing_error_if(lpeg.Cp() * lpeg.P("%") * lpeg.R("09") * lpeg.Cp(), "Group does not yet exist, or is never created:")

g.balanced_string = lpeg.P("%b")
    * lpeg.Ct(base.capture_type("balanced_string") * lpeg.Cg(lpeg.P(1), "open") * lpeg.Cg(lpeg.P(1), "close"))

g.group = lpeg.P("(")
    * lpeg.Ct(
      base.capture_type("group")
      * lpeg.Cg(lpeg.Cmt(lpeg.P(""), base.get_group_number) / "Group %1", "name")
      * lpeg.Cg(lpeg.Ct(base.capture_type("expression") * (lpeg.V("component") - lpeg.P(")")) ^ 1), "sub_expr")
    )
    * lpeg.P(")")

g.quantified = lpeg.Ct(
  base.capture_type("quantified_expression") * lpeg.Cg(lpeg.V("character_class"), "sub_expr") * lpeg.V("quantifier")
)

g.position_capture = lpeg.P("()") * lpeg.Ct(base.capture_type("position_capture"))

g.character_class = lpeg.V("escaped_character")
    + lpeg.V("special_character_class")
    + lpeg.V("character_set")
    + lpeg.V("literal_character")

g.character_set_item = lpeg.V("escaped_character")
    + lpeg.V("special_character_class")
    + lpeg.V("character_range")
    + lpeg.V("any_character")
    + lpeg.V("literal_character")

g.escaped_character = lpeg.P("%")
    * lpeg.Ct(base.capture_type("character") * lpeg.Cg(lpeg.P(1) - lpeg.R("az", "AZ", "09"), "character"))

g.character_range = lpeg.Ct(
  base.capture_type("character_range")
  * lpeg.Cg(lpeg.P(1) - lpeg.P("]"), "start")
  * lpeg.P("-")
  * lpeg.Cg(lpeg.P(1) - lpeg.P("]"), "finish")
)

-- Lua is very lenient about special characters in strange places.
-- For example, * at the beginning of an expression is fine.
g.meta_characters = lpeg.V("never_match")

g.literal_character = lpeg.Ct(base.capture_type("character") * lpeg.Cg(lpeg.P(1), "character"))

local function quantifier(pattern, min, max, greediness)
  return lpeg.P(pattern)
      * lpeg.Cg(lpeg.P(true) / min, "min")
      * lpeg.Cg(lpeg.P(true) / max, "max")
      * lpeg.Cg(lpeg.P(true) / greediness, "greedy")
end

g.quantifier = quantifier("*", "0", "Infinity", "greedy")
    + quantifier("+", "1", "Infinity", "greedy")
    + quantifier("-", "0", "Infinity", "lazy")
    + quantifier("?", "0", "1", "greedy")

g.special_character_class = lpeg.P("%")
    * lpeg.Ct(
      base.capture_type("character_class")
      * (
        lpeg.Cg(lpeg.P("a") / "any_letter", "class")
        + lpeg.Cg(lpeg.P("A") / "any_letter", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("c") / "any_control_character", "class")
        + lpeg.Cg(lpeg.P("C") / "any_control_character", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("d") / "any_digit", "class")
        + lpeg.Cg(lpeg.P("D") / "any_digit", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("l") / "any_lower_case_letter", "class")
        + lpeg.Cg(lpeg.P("L") / "any_lower_case_letter", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("p") / "any_punctuation_character", "class")
        + lpeg.Cg(lpeg.P("P") / "any_punctuation_character", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("s") / "any_whitespace_character", "class")
        + lpeg.Cg(lpeg.P("S") / "any_whitespace_character", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("u") / "any_uppercase_letter", "class")
        + lpeg.Cg(lpeg.P("U") / "any_uppercase_letter", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("w") / "any_alphanumeric_character", "class")
        + lpeg.Cg(lpeg.P("W") / "any_alphanumeric_character", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("x") / "any_hexadecimal_digit", "class")
        + lpeg.Cg(lpeg.P("X") / "any_hexadecimal_digit", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
        + lpeg.Cg(lpeg.P("z") / "zero_character", "class")
        + lpeg.Cg(lpeg.P("Z") / "zero_character", "class") * lpeg.Cg(lpeg.P(true) / "true", "negate")
      )
    )

return lpeg.P(vim.tbl_extend("force", base.grammar, g))
