-- Component base class/interface
local M = {}

--- Component interface that all components should implement
---@class Component
---@field name string Component identifier
---@field config table Default configuration
local Component = {}

--- Render component in a specific container
---@param container string Container type ("popup", "lhs", "main", etc.)
---@param config table? Component configuration
---@return number? window_id Created or focused window ID
function Component:render_in(container, config)
  error("render_in must be implemented by component")
end

--- Create a new component window (for layout system)
---@param config table Component configuration
---@param parent_win number? Parent window ID
---@return number window_id Created window ID
function Component:create_window(config, parent_win)
  error("create_window must be implemented by component")
end

--- Open/show the component in its preferred container
---@param config table? Runtime configuration
function Component:open(config)
  error("open must be implemented by component") 
end

--- Close/hide the component
function Component:close()
  error("close must be implemented by component")
end

--- Check if component is currently open/visible
---@return boolean
function Component:is_open()
  error("is_open must be implemented by component")
end

--- Toggle component visibility
---@param config table? Runtime configuration
function Component:toggle(config)
  if self:is_open() then
    self:close()
  else
    self:open(config)
  end
end

--- Get component state for debugging/inspection
---@return table
function Component:get_state()
  return {}
end

--- Clean up component resources
function Component:cleanup()
  -- Default implementation does nothing
  -- Components can override for cleanup
end

--- Validate component configuration
---@param config table Configuration to validate
---@return boolean valid, string? error_message
function Component:validate_config(config)
  return true  -- Default: accept all configs
end

--- Create a new component class
---@param name string Component name
---@param impl table Component implementation
---@return table component Component instance
function M.create_component(name, impl)
  local component = vim.tbl_extend("force", Component, impl)
  component.name = name
  component.config = component.config or {}
  
  -- Validate that required methods are implemented
  local required_methods = {"create_window", "open", "close", "is_open"}
  for _, method in ipairs(required_methods) do
    if type(component[method]) ~= "function" then
      error(string.format("Component '%s' must implement method '%s'", name, method))
    end
  end
  
  return component
end

--- Component registry for factory pattern
local components = {}

function M.register_component(name, component)
  components[name] = component
end

function M.get_component(name)
  return components[name]
end

function M.list_components()
  return vim.tbl_keys(components)
end

return M
