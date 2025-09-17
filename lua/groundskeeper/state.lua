-- Example improved state management
local M = {}

-- Private state
local _state = {
  layers = {
    base = { active = false, config = {} },
    ivy_popup = { active = false, config = {} },
  },
  components = {
    file_manager = { buf = nil, type = "netrw" }, -- or "telescope", "oil", etc.
    terminal = { buf = nil, shell = nil },
    lhs_content = { buf = nil, type = "scratch", win = nil }, -- what goes in left sidebar
  },
  ui = {
    popup = { win = nil, buf = nil, open = false, current_component = nil },
    lhs = { win = nil, open = false, current_component = nil },
    padding = nil,
    layout_cache = {},
  }
}

-- State getters (read-only access)
function M.get_layer_state(layer_name)
  return vim.deepcopy(_state.layers[layer_name] or {})
end

function M.get_component_state(component_name)
  return vim.deepcopy(_state.components[component_name] or {})
end

function M.is_layer_active(layer_name)
  return _state.layers[layer_name] and _state.layers[layer_name].active or false
end

function M.get_ui_state()
  return vim.deepcopy(_state.ui)
end

function M.set_ui_state(updates)
  _state.ui = vim.tbl_extend("force", _state.ui, updates)
end

-- State setters with validation
function M.set_layer_active(layer_name, active, config)
  if not _state.layers[layer_name] then
    _state.layers[layer_name] = { active = false, config = {} }
  end
  _state.layers[layer_name].active = active
  if config then
    _state.layers[layer_name].config = vim.tbl_extend("force", _state.layers[layer_name].config, config)
  end
end

function M.set_component_state(component_name, updates)
  if not _state.components[component_name] then
    _state.components[component_name] = {}
  end
  _state.components[component_name] = vim.tbl_extend("force", _state.components[component_name], updates)
end

-- Utility for state watching/debugging
function M.subscribe(callback)
  -- Could implement state change notifications here
  -- Useful for debugging and reactive updates
end

function M.dump_state()
  return vim.deepcopy(_state)
end

return M
