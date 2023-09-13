local grammar = [=[
regular_expression              <- regular_expression_component*
one_of_many_expressions         <- regular_expression (or_operator regular_expression)+
regular_expression_component    <- one_of_many_expressions 
                                   / !special_character
                                   / group
                                   / set_of_characters
set_of_characters               <- complement_set_of_characters / normal_set_of_characters
complement_set_of_characters    <- '[^' set_of_characters_internal ']'
normal_set_of_characters        <- '[' set_of_characters_internal ']'
set_of_characters_internal      <- ('\-'
                                   / range
                                   / .)*
group                           <- '(' regular_expression ')'
range                           <- . '-' .
special_character               <- (any_character
                                   / start_of_string
                                   / end_of_string
                                   / zero_or_more_repeats
                                   / one_or_more_repeats
                                   / optional_pattern
                                   / escape_character
                                   / left_square_bracket
                                   / right_square_bracket
                                   / or_operator
                                   / left_bracket
                                   / right_bracket)
any_character                   <- '.'
start_of_string                 <- '^'
end_of_string                   <- '$'
zero_or_more_repeats            <- '*'
one_or_more_repeats             <- '+'
optional_pattern                <- '?'
escape_character                <- '\'
left_square_bracket             <- '['
right_square_bracket            <- ']'
or_operator                     <- '|'
left_bracket                    <- '('
right_bracket                   <- '('
]=]

local re = require("re")
print(re.compile(grammar):match("\\\\\\\\\\++hhhhhello"))
