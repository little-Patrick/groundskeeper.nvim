-- LHS Content Component - handles content for left-hand sidebar
local component_base = require("groundskeeper.component_base")
local state = require("groundskeeper.state")

local M = {}

-- Default configuration
M.config = {
  type = "scratch", -- "scratch", "file", "symbols", "outline"
  auto_focus = false,
  persist_buffer = true,
}

--- Render LHS content in specific container
---@param container string Container type ("lhs", "main", "popup")
---@param config table? Component configuration
---@return number? window_id Created or focused window ID
function M:render_in(container, config)
  config = vim.tbl_extend("force", self.config, config or {})
  
  if container == "lhs" then
    return self:render_in_lhs(config)
  elseif container == "main" then
    return self:render_in_main(config)
  elseif container == "popup" then
    return self:render_in_popup(config)
  else
    vim.notify("Unknown container: " .. container, vim.log.levels.ERROR)
    return nil
  end
end

--- Render in left sidebar (primary use case)
function M:render_in_lhs(config)
  local ui_state = state.get_ui_state()
  local lhs_win = ui_state.lhs and ui_state.lhs.win
  
  if not lhs_win or not vim.api.nvim_win_is_valid(lhs_win) then
    vim.notify("No valid LHS window found", vim.log.levels.ERROR)
    return nil
  end
  
  vim.api.nvim_set_current_win(lhs_win)
  return self:create_or_focus_content(config)
end

--- Render in main window
function M:render_in_main(config)
  return self:create_or_focus_content(config)
end

--- Render in popup
function M:render_in_popup(config)
  local ui_state = state.get_ui_state()
  local popup_win = ui_state.popup and ui_state.popup.win
  
  if not popup_win or not vim.api.nvim_win_is_valid(popup_win) then
    vim.notify("No valid popup window found", vim.log.levels.ERROR)
    return nil
  end
  
  vim.api.nvim_set_current_win(popup_win)
  return self:create_or_focus_content(config)
end

--- Create or focus content based on type
function M:create_or_focus_content(config)
  if config.type == "scratch" then
    return self:create_scratch_buffer(config)
  elseif config.type == "file" then
    return self:create_file_explorer(config)
  elseif config.type == "symbols" then
    return self:create_symbols_outline(config)
  elseif config.type == "outline" then
    return self:create_outline(config)
  else
    vim.notify("Unknown LHS content type: " .. config.type, vim.log.levels.WARN)
    return self:create_scratch_buffer(config)
  end
end

--- Create scratch buffer
function M:create_scratch_buffer(config)
  local lhs_state = state.get_component_state("lhs_content")
  local current_win = vim.api.nvim_get_current_win()
  
  -- Check if we have a persistent scratch buffer
  if config.persist_buffer and lhs_state.buf and vim.api.nvim_buf_is_valid(lhs_state.buf) then
    vim.api.nvim_win_set_buf(current_win, lhs_state.buf)
    return current_win
  end
  
  -- Create new scratch buffer
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_name(buf, "Groundskeeper Scratch")
  
  -- Set some helpful content
  local lines = {
    "# Groundskeeper Scratch Buffer",
    "",
    "This is a scratch buffer for notes and temporary content.",
    "Changes are not saved automatically.",
    "",
    "Use this space for:",
    "- Quick notes",
    "- Code snippets",
    "- Temporary calculations",
    "- Project planning",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  vim.api.nvim_win_set_buf(current_win, buf)
  
  -- Store buffer for persistence
  if config.persist_buffer then
    state.set_component_state("lhs_content", { buf = buf, type = "scratch" })
  end
  
  return current_win
end

--- Create file explorer in LHS
function M:create_file_explorer(config)
  vim.cmd("Ex")
  return vim.api.nvim_get_current_win()
end

--- Create symbols outline (requires LSP)
function M:create_symbols_outline(config)
  local has_symbols, symbols = pcall(require, "symbols-outline")
  if has_symbols then
    symbols.open_outline()
    return vim.api.nvim_get_current_win()
  else
    vim.notify("symbols-outline not available, falling back to scratch", vim.log.levels.WARN)
    return self:create_scratch_buffer(config)
  end
end

--- Create outline (aerial or similar)
function M:create_outline(config)
  local has_aerial, aerial = pcall(require, "aerial")
  if has_aerial then
    aerial.open()
    return vim.api.nvim_get_current_win()
  else
    vim.notify("aerial not available, falling back to scratch", vim.log.levels.WARN)
    return self:create_scratch_buffer(config)
  end
end

--- Create window for layout system
function M:create_window(config, parent_win)
  if parent_win and parent_win ~= 0 then
    vim.api.nvim_set_current_win(parent_win)
  end
  return self:create_or_focus_content(config)
end

--- Open LHS content (legacy interface)
function M:open(config)
  return self:render_in("lhs", config)
end

--- Close LHS content
function M:close()
  local lhs_state = state.get_component_state("lhs_content")
  
  -- If not persisting, clean up buffer
  if not self.config.persist_buffer and lhs_state.buf and vim.api.nvim_buf_is_valid(lhs_state.buf) then
    pcall(vim.api.nvim_buf_delete, lhs_state.buf, { force = true })
    state.set_component_state("lhs_content", { buf = nil })
  end
end

--- Check if LHS content is open
function M:is_open()
  local ui_state = state.get_ui_state()
  return ui_state.lhs and ui_state.lhs.current_component == "lhs_content"
end

--- Switch content type
function M:switch_type(new_type, config)
  config = config or {}
  config.type = new_type
  return self:create_or_focus_content(config)
end

--- Get component state
function M:get_state()
  local lhs_state = state.get_component_state("lhs_content")
  return {
    type = lhs_state.type or self.config.type,
    has_buffer = lhs_state.buf and vim.api.nvim_buf_is_valid(lhs_state.buf) or false,
    buffer_id = lhs_state.buf,
    is_open = self:is_open(),
  }
end

--- Validate configuration
function M:validate_config(config)
  if config.type and not vim.tbl_contains({"scratch", "file", "symbols", "outline"}, config.type) then
    return false, "Invalid LHS content type: " .. config.type
  end
  return true
end

-- Create component instance
local lhs_content = component_base.create_component("lhs_content", M)

-- Register component
component_base.register_component("lhs_content", lhs_content)

return lhs_content
