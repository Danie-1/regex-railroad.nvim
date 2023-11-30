local M = {}

local base = require("regex-railroad.parsers.grammars.base")
local lpeg = require("regex-railroad.lpeg")
local g = base.grammar

M[1] = "grammar"

M.grammar =
  lpeg.Ct(base.capture_type("expression") * lpeg.V("sub_expr") * (lpeg.V("fail_if_close_bracket") + (-lpeg.P(1))))

g.unquantified = lpeg.V("numbered_group")
  + lpeg.V("named_group")
  + lpeg.V("named_backreference")
  + lpeg.V("fail_if_unrecognised_group_type")
  + lpeg.V("fail_if_open_bracket")
  + lpeg.V("character_set")
  + lpeg.V("pcre_q_e_sequence")
  + lpeg.V("anchor_no_quantifier")
  + lpeg.V("invalid_characters")
  + lpeg.V("assert_no_quantifier")
  + lpeg.V("literal_character")

g.named_group = lpeg.Ct(
  lpeg.P("(?P<")
    * base.capture_type("group")
    * (lpeg.Cg(
      lpeg.Cmt(lpeg.Cp() * lpeg.C(lpeg.V("valid_group_name")) * lpeg.Cp(), base.register_named_group) / "Group '%1'",
      "name"
    ) + lpeg.V("invalid_character_in_group_name"))
    * (lpeg.P(">") + lpeg.V("invalid_character_in_group_name"))
    * lpeg.Cg(lpeg.Ct(base.capture_type("expression") * lpeg.V("sub_expr")), "sub_expr")
    * lpeg.P(")")
)

g.named_backreference = lpeg.Ct(
  lpeg.P("(?P=")
    * base.capture_type("match_capture")
    * (lpeg.Cg(lpeg.Cmt(lpeg.V("valid_group_name"), base.ensure_group_already_exists) / "'%0'", "name") + base.parsing_error_if(
      lpeg.Cp() * lpeg.V("valid_group_name") * lpeg.Cp(),
      "Group does not yet exist, or is never created:"
    ) + lpeg.V("invalid_character_in_group_name"))
    * (lpeg.P(")") + lpeg.V("invalid_character_in_group_name"))
)

return lpeg.P(vim.tbl_extend("force", g, M))
