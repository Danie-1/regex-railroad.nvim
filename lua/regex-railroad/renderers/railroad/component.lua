---@alias ExpressionComponent
---| Anchor
---| BalancedString
---| Character
---| CharacterClass
---| CharacterSet
---| MatchCapture
---| Group
---| PositionCapture
---| QuantifiedExpression

---@class Expression
---@field type 'expression'
---@field [integer] ExpressionComponent

---@alias char string

---@class Anchor
---@field type 'anchor'
---@field description string

---@class BalancedString
---@field type 'balanced_string'
---@field open char
---@field close char

---@class Character
---@field type 'character'
---@field character char

---@class CharacterClass
---@field type 'character_class'
---@field class string

---@class CharacterRange
---@field type 'character_range'
---@field start char
---@field finish char

---@class CharacterSet
---@field type 'character_set'
---@field items CharacterSetItem[]
---@field complement 'true'|'false'

---@alias CharacterSetItem
---| char
---| CharacterRange
---| CharacterClass
---| Character

---@class MatchCapture
---@field type 'match_capture'
---@field name string

---@class Group
---@field type 'group'
---@field sub_expr Expression
---@field name string?

---@class PositionCapture
---@field type 'position_capture'

---@class QuantifiedExpression
---@field type 'quantified_expression'
---@field min integer
---@field max integer|'Infinity'
---@field sub_expr Expression
---@field greedy string
