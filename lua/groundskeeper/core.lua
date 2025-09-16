local M = {}

-- Simple layer registry
M.layers = {}
M._active = {}

--- Register a layer (function or table with lifecycle methods)
---@param name string
---@param layer fun()|table
function M.register_layer(name, layer)
  M.layers[name] = layer
end

--- Is a layer active?
---@param name string
function M.is_active(name)
  local layer = M.layers[name]
  if not layer then return false end
  if type(layer) == "table" and type(layer.is_active) == "function" then
    return layer.is_active()
  end
  return M._active[name] or false
end

--- Activate
function M.activate_layer(name, ...)
  local layer = M.layers[name]
  if not layer then
    vim.notify("groundskeeper: layer '" .. name .. "' not found", vim.log.levels.WARN)
    return
  end
  if type(layer) == "function" then
    layer(...)
    M._active[name] = true
    return
  end
  if type(layer.activate) == "function" then
    layer.activate(...)
    M._active[name] = true
  end
end

--- Deactivate
function M.deactivate_layer(name)
  local layer = M.layers[name]
  if not layer then return end
  if type(layer) == "table" and type(layer.deactivate) == "function" then
    layer.deactivate()
    M._active[name] = false
  end
end

--- Toggle
function M.toggle_layer(name, ...)
  local layer = M.layers[name]
  if not layer then return end
  if type(layer) == "table" and type(layer.toggle) == "function" then
    layer.toggle(...)
    M._active[name] = not M._active[name]
    return
  end
  if M.is_active(name) then
    M.deactivate_layer(name)
  else
    M.activate_layer(name, ...)
  end
end

return M
