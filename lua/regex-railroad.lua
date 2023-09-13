---@class Config
local config = {
  highlights = {
    anchor = "Keyword",
    balanced_string = "Delimiter",
    capture_group = "StorageClass",
    character = "String",
    character_class = "Special",
    character_set = "Character",
    match_capture = "Constant",
    railroad = "Normal",
  },
  railroad_characters = {
    block = {
      left = "█",
      right = "█",
      top = "▄",
      bottom = "▀",
    },
    capture_group_characters = {
      vertical_through_rail = "╫",
      vertical = "║",
      horizontal = "═",
      top_left = "╔",
      top_right = "╗",
      bottom_right = "╝",
      bottom_left = "╚",
    },
    up_down_left_right = "┼",
    up_down_left = "┤",
    up_down_right = "├",
    up_down = "│",
    up_left_right = "┴",
    up_left = "╯",
    up_right = "╰",
    down_left_right = "┬",
    down_left = "╮",
    down_right = "╭",
    left_right = "─",
    arrow_left = "<",
    arrow_right = ">",
  },
  create_panel = function()
    local Split = require("nui.split")
    return Split({
      enter = false,
      relative = "editor",
      position = "bottom",
      size = "40%",
      buf_options = {
        filetype = "regex-railroad-rendered",
      },
      win_options = {
        wrap = false,
        sidescrolloff = 999,
        virtualedit = "all",
      },
      ns_id = "regex-railroad",
    })
  end,
  clear = false,
}

local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

local panel_is_open = false

local panel

local function create_panel()
  panel = config.create_panel()
  panel:mount()
  panel_is_open = true
end

function M.show_panel()
  panel_is_open = true
  if panel and panel.bufnr then
    panel:show()
  else
    create_panel()
  end
end

function M.hide_panel()
  panel_is_open = false
  panel:hide()
end

function M.toggle_panel()
  if panel_is_open then
    M.hide_panel()
  else
    M.show_panel()
  end
end

function M.view_expression(expression, flavour)
  local parse_expression = require("regex-railroad.parse-expression").parse_expression

  M.show_panel()

  vim.api.nvim_buf_set_option(panel.bufnr, "modifiable", true)
  if M.config.clear then
    vim.api.nvim_buf_set_lines(panel.bufnr, 0, -1, false, {})
  else
    vim.api.nvim_buf_set_lines(panel.bufnr, 0, 0, false, { "", "", "", "", "" })
  end

  local railroad_renderer = require("regex-railroad.renderers.railroad")
  local parsed_expression = parse_expression(expression, flavour)
  if not parsed_expression then
    vim.api.nvim_buf_set_lines(
      panel.bufnr,
      0,
      0,
      false,
      { 'Failed to parse expression "' .. expression .. '". If you think this is a bug, please report.' }
    )
    return
  else
    local rendered_diagram = railroad_renderer.render(parsed_expression)

    rendered_diagram:render_to_buffer(panel.bufnr)
    vim.api.nvim_buf_set_option(panel.bufnr, "modifiable", false)
  end
  vim.api.nvim_win_set_cursor(panel.winid, { 1, 0 })
end

function M.render_expression_at_cursor()
  local string_processor = require("regex-railroad.strings." .. vim.bo.filetype)
  local unescaped_string = string_processor.get_unescaped_string_at_cursor()
  M.view_expression(unescaped_string, vim.bo.filetype)
end

return M
