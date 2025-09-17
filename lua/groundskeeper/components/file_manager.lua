-- File Manager Component - handles file browsing in various containers
local component_base = require("groundskeeper.component_base")
local state = require("groundskeeper.state")

local M = {}

-- Default configuration
M.config = {
  type = "netrw", -- "netrw", "telescope", "oil"
  follow_current = true,
  show_hidden = false,
  theme = "default", -- for telescope: "default", "ivy", "dropdown"
}

--- Render file manager in specific container
---@param container string Container type ("popup", "lhs", "main")
---@param config table? Component configuration
---@return number? window_id Created or focused window ID
function M:render_in(container, config)
  config = vim.tbl_extend("force", self.config, config or {})
  
  if container == "popup" then
    return self:render_in_popup(config)
  elseif container == "lhs" then
    return self:render_in_lhs(config)
  elseif container == "main" then
    return self:render_in_main(config)
  else
    vim.notify("Unknown container: " .. container, vim.log.levels.ERROR)
    return nil
  end
end

--- Render in popup container
function M:render_in_popup(config)
  local ui_state = state.get_ui_state()
  local popup_win = ui_state.popup and ui_state.popup.win
  
  if not popup_win or not vim.api.nvim_win_is_valid(popup_win) then
    vim.notify("No valid popup window found", vim.log.levels.ERROR)
    return nil
  end
  
  vim.api.nvim_set_current_win(popup_win)
  
  if config.type == "telescope" then
    return self:render_telescope(config)
  elseif config.type == "oil" then
    return self:render_oil(config)
  else
    return self:render_netrw(config)
  end
end

--- Render in left sidebar
function M:render_in_lhs(config)
  local ui_state = state.get_ui_state()
  local lhs_win = ui_state.lhs and ui_state.lhs.win
  
  if not lhs_win or not vim.api.nvim_win_is_valid(lhs_win) then
    vim.notify("No valid LHS window found", vim.log.levels.ERROR)
    return nil
  end
  
  vim.api.nvim_set_current_win(lhs_win)
  return self:render_netrw(config) -- LHS typically uses netrw
end

--- Render in main window
function M:render_in_main(config)
  return self:render_netrw(config)
end

--- Render using telescope
function M:render_telescope(config)
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("Telescope not available, falling back to netrw", vim.log.levels.WARN)
    return self:render_netrw(config)
  end
  
  local themes = require("telescope.themes")
  local opts = {}
  
  if config.theme == "ivy" then
    opts = themes.get_ivy()
  elseif config.theme == "dropdown" then
    opts = themes.get_dropdown()
  end
  
  if config.show_hidden then
    opts.hidden = true
  end
  
  require("telescope.builtin").find_files(opts)
  return vim.api.nvim_get_current_win()
end

--- Render using oil.nvim
function M:render_oil(config)
  local has_oil, oil = pcall(require, "oil")
  if not has_oil then
    vim.notify("Oil not available, falling back to netrw", vim.log.levels.WARN)
    return self:render_netrw(config)
  end
  
  oil.open()
  return vim.api.nvim_get_current_win()
end

--- Render using netrw
function M:render_netrw(config)
  vim.cmd("Ex")
  
  if config.show_hidden then
    vim.cmd("let g:netrw_hide=0")
  end
  
  return vim.api.nvim_get_current_win()
end

--- Create window for layout system
function M:create_window(config, parent_win)
  if parent_win and parent_win ~= 0 then
    vim.api.nvim_set_current_win(parent_win)
  end
  return self:render_netrw(config)
end

--- Open file manager (legacy interface)
function M:open(config)
  return self:render_in("popup", config)
end

--- Close file manager
function M:close()
  -- File manager typically doesn't need special cleanup
  -- The container (popup/window) handles closing
end

--- Check if file manager is open
function M:is_open()
  local ui_state = state.get_ui_state()
  return (ui_state.popup and ui_state.popup.current_component == "file_manager") or
         (ui_state.lhs and ui_state.lhs.current_component == "file_manager")
end

--- Get component state
function M:get_state()
  return {
    type = self.config.type,
    container = self:is_open() and "unknown" or nil
  }
end

--- Validate configuration
function M:validate_config(config)
  if config.type and not vim.tbl_contains({"netrw", "telescope", "oil"}, config.type) then
    return false, "Invalid file manager type: " .. config.type
  end
  return true
end

-- Create component instance
local file_manager = component_base.create_component("file_manager", M)

-- Register component
component_base.register_component("file_manager", file_manager)

return file_manager
