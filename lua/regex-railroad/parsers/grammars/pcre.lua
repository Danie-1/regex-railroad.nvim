-- See https://www.pcre.org/original/doc/html/pcrepattern.html

local M = {
  grammar = {},
}

local g = M.grammar

local base = require("regex-railroad.parsers.grammars.base")
local lpeg = require("regex-railroad.lpeg")

g.pcre_utf8_support_flag = lpeg.P("UTF") * (lpeg.P("8") + lpeg.P("16") + lpeg.P("32") + lpeg.P(""))

g.pcre_no_auto_possess = lpeg.P("NO_AUTO_POSSESS")

g.pcre_no_start_opt = lpeg.P("NO_START_OPT")

g.pcre_newline_convention = lpeg.P("CR") + lpeg.P("LF") + lpeg.P("CRLF") + lpeg.P("ANYCRLF") + lpeg.P("ANY")

g.pcre_match_and_recursion_limits = lpeg.P("LIMIT_")
  * (lpeg.P("MATCH") * lpeg.P("RECURSION"))
  * lpeg.P("=")
  * lpeg.R("09") ^ 1

g.pcre_global_flags = lpeg.Ct(
  base.capture_type("global_flags")
    * (lpeg.P("(*") * lpeg.C(
        lpeg.V("pcre_utf8_support_flag")
          + lpeg.V("pcre_no_auto_possess")
          + lpeg.V("pcre_no_start_opt")
          + lpeg.V("pcre_newline_convention")
          + lpeg.V("pcre_match_and_recursion_limits")
      ) * lpeg.P(")"))
      ^ 0
)

return M
