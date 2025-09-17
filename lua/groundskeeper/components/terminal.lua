-- Terminal Component - handles terminal in various containers
local component_base = require("groundskeeper.component_base")
local state = require("groundskeeper.state")

local M = {}

-- Default configuration
M.config = {
  shell = nil, -- use default shell
  persist_session = true,
  start_insert = true,
  close_on_exit = true,
}

--- Render terminal in specific container
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
  return self:create_or_focus_terminal(config)
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
  return self:create_or_focus_terminal(config)
end

--- Render in main window
function M:render_in_main(config)
  return self:create_or_focus_terminal(config)
end

--- Create or focus existing terminal
function M:create_or_focus_terminal(config)
  local terminal_state = state.get_component_state("terminal")
  local current_win = vim.api.nvim_get_current_win()
  
  -- Check if we have a persistent terminal buffer
  if config.persist_session and terminal_state.buf and vim.api.nvim_buf_is_valid(terminal_state.buf) then
    local buf_type = vim.api.nvim_buf_get_option(terminal_state.buf, "buftype")
    if buf_type == "terminal" then
      -- Use existing terminal
      vim.api.nvim_win_set_buf(current_win, terminal_state.buf)
      if config.start_insert then
        vim.cmd("startinsert")
      end
      return current_win
    end
  end
  
  -- Create new terminal
  local shell_cmd = config.shell or vim.o.shell
  if shell_cmd and shell_cmd ~= "" then
    vim.cmd("terminal " .. shell_cmd)
  else
    vim.cmd("terminal")
  end
  
  local terminal_buf = vim.api.nvim_get_current_buf()
  
  -- Store terminal buffer for persistence
  if config.persist_session then
    state.set_component_state("terminal", { buf = terminal_buf })
  end
  
  -- Set up terminal options
  if config.close_on_exit then
    vim.api.nvim_buf_set_option(terminal_buf, "buflisted", false)
  end
  
  if config.start_insert then
    vim.cmd("startinsert")
  end
  
  return current_win
end

--- Create window for layout system
function M:create_window(config, parent_win)
  if parent_win and parent_win ~= 0 then
    vim.api.nvim_set_current_win(parent_win)
  end
  return self:create_or_focus_terminal(config)
end

--- Open terminal (legacy interface)
function M:open(config)
  return self:render_in("popup", config)
end

--- Close terminal
function M:close()
  local terminal_state = state.get_component_state("terminal")
  
  -- If not persisting, clean up terminal buffer
  if not self.config.persist_session and terminal_state.buf and vim.api.nvim_buf_is_valid(terminal_state.buf) then
    pcall(vim.api.nvim_buf_delete, terminal_state.buf, { force = true })
    state.set_component_state("terminal", { buf = nil })
  end
end

--- Check if terminal is open
function M:is_open()
  local ui_state = state.get_ui_state()
  return (ui_state.popup and ui_state.popup.current_component == "terminal") or
         (ui_state.lhs and ui_state.lhs.current_component == "terminal")
end

--- Get terminal buffer ID
function M:get_terminal_buf()
  local terminal_state = state.get_component_state("terminal")
  return terminal_state.buf
end

--- Send text to terminal
function M:send_text(text)
  local buf = self:get_terminal_buf()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local chan = vim.api.nvim_buf_get_option(buf, "channel")
    if chan and chan > 0 then
      vim.api.nvim_chan_send(chan, text)
      return true
    end
  end
  return false
end

--- Get component state
function M:get_state()
  local terminal_state = state.get_component_state("terminal")
  return {
    has_buffer = terminal_state.buf and vim.api.nvim_buf_is_valid(terminal_state.buf) or false,
    buffer_id = terminal_state.buf,
    is_open = self:is_open(),
  }
end

--- Validate configuration
function M:validate_config(config)
  -- All terminal config options are optional
  return true
end

-- Create component instance
local terminal = component_base.create_component("terminal", M)

-- Register component
component_base.register_component("terminal", terminal)

return terminal
