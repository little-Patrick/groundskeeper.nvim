-- Layout system for UI composition
local M = {}

-- Layout cache for quick switching
local layout_cache = {}
local current_layout = nil

--- Layout specification structure
---@class LayoutSpec
---@field id string Unique layout identifier  
---@field direction "horizontal"|"vertical" Split direction
---@field size number Size ratio (0.0-1.0) or absolute pixels
---@field children table[] Child layout specs or components
---@field component string? Component name to render in this pane
---@field config table? Component configuration

--- Built-in layout presets
local presets = {
  -- No-neck-pain style: centered code with side padding
  centered = {
    id = "centered",
    direction = "horizontal",
    children = {
      { component = "padding", size = 0.2 },
      { component = "main", size = 0.6 },
      { component = "padding", size = 0.2 },
    }
  },
  
  -- LSP/Navigation focused layout
  lsp_nav = {
    id = "lsp_nav", 
    direction = "horizontal",
    children = {
      { 
        component = "file_tree", 
        size = 0.25,
        config = { show_git_status = true, follow_current = true }
      },
      {
        direction = "vertical",
        size = 0.55,
        children = {
          { component = "main", size = 0.7 },
          { component = "terminal", size = 0.3 }
        }
      },
      {
        direction = "vertical", 
        size = 0.2,
        children = {
          { component = "symbols_outline", size = 0.6 },
          { component = "diagnostics", size = 0.4 }
        }
      }
    }
  },
  
  -- Debugging layout
  debug = {
    id = "debug",
    direction = "vertical", 
    children = {
      {
        direction = "horizontal",
        size = 0.7,
        children = {
          { component = "main", size = 0.6 },
          { component = "dap_sidebar", size = 0.4 }
        }
      },
      {
        direction = "horizontal",
        size = 0.3,
        children = {
          { component = "repl", size = 0.5 },
          { component = "dap_console", size = 0.5 }
        }
      }
    }
  },
  
  -- Split screen development (e.g., implementation + test)
  split_dev = {
    id = "split_dev",
    direction = "horizontal",
    children = {
      { component = "main", size = 0.5 },
      { component = "secondary", size = 0.5 }  -- test file, header file, etc.
    }
  }
}

--- Apply a layout specification
---@param layout_spec LayoutSpec
---@param parent_win number? Parent window ID
function M.apply_layout(layout_spec, parent_win)
  parent_win = parent_win or 0  -- 0 = current window
  
  -- Cache current layout before switching
  if current_layout then
    layout_cache[current_layout] = M.capture_current_layout()
  end
  
  -- Clear existing layout
  M.clear_layout()
  
  -- Build new layout
  local root_win = M.build_layout_tree(layout_spec, parent_win)
  current_layout = layout_spec.id
  
  return root_win
end

--- Recursively build layout tree
function M.build_layout_tree(spec, parent_win)
  if spec.component then
    -- Leaf node: create component
    return M.create_component_window(spec, parent_win)
  elseif spec.children then
    -- Branch node: create splits
    return M.create_split_layout(spec, parent_win)
  end
end

--- Create a window for a specific component
function M.create_component_window(spec, parent_win)
  local component_name = spec.component
  local config = spec.config or {}
  
  -- Get component factory
  local component = require("groundskeeper.components." .. component_name)
  if component and component.create_window then
    return component.create_window(config, parent_win)
  end
  
  -- Fallback: create basic window
  vim.cmd(parent_win == 0 and "new" or "split")
  return vim.api.nvim_get_current_win()
end

--- Create split layout with children
function M.create_split_layout(spec, parent_win)
  local direction = spec.direction or "horizontal"
  local children = spec.children or {}
  
  if #children == 0 then return parent_win end
  
  -- Create first child in current window
  local first_win = M.build_layout_tree(children[1], parent_win)
  local current_win = first_win
  
  -- Create splits for remaining children
  for i = 2, #children do
    local child_spec = children[i]
    
    -- Calculate split command
    local split_cmd = direction == "horizontal" and "vsplit" or "split"
    vim.api.nvim_set_current_win(current_win)
    vim.cmd(split_cmd)
    
    current_win = vim.api.nvim_get_current_win()
    M.build_layout_tree(child_spec, current_win)
    
    -- Set window size if specified
    if child_spec.size then
      M.set_window_size(current_win, child_spec.size, direction)
    end
  end
  
  return first_win
end

--- Set window size based on ratio or absolute value
function M.set_window_size(win, size, direction)
  if size <= 1.0 then  -- Ratio
    local total_size = direction == "horizontal" and vim.o.columns or vim.o.lines
    size = math.floor(total_size * size)
  end
  
  if direction == "horizontal" then
    vim.api.nvim_win_set_width(win, size)
  else
    vim.api.nvim_win_set_height(win, size)
  end
end

--- Switch to a preset layout
function M.switch_to_preset(preset_name, config)
  local preset = presets[preset_name]
  if not preset then
    vim.notify("Unknown layout preset: " .. preset_name, vim.log.levels.ERROR)
    return
  end
  
  -- Merge custom config if provided
  if config then
    preset = vim.tbl_deep_extend("force", preset, config)
  end
  
  return M.apply_layout(preset)
end

--- Register a custom layout preset
function M.register_preset(name, layout_spec)
  presets[name] = layout_spec
end

--- Get available presets
function M.get_presets()
  return vim.tbl_keys(presets)
end

--- Capture current window layout for caching
function M.capture_current_layout()
  -- This could save current window layout using vim.fn.winlayout()
  -- For now, just return a simple structure
  return {
    winlayout = vim.fn.winlayout(),
    timestamp = vim.fn.localtime()
  }
end

--- Restore cached layout
function M.restore_layout(layout_id)
  local cached = layout_cache[layout_id]
  if cached then
    -- Implementation would restore the cached layout
    -- This is complex and might not always be reliable
    vim.notify("Layout restoration not fully implemented yet", vim.log.levels.INFO)
  end
end

--- Clear current layout (close all splits except main)
function M.clear_layout()
  -- Close all windows except the first one
  vim.cmd("only")
end

return M
