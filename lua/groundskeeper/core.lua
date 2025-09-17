local M = {}

-- Enhanced layer registry with dependencies and priorities
M.layers = {}
M._active = {}
M._config = {}

--- Register a layer with metadata
---@param name string
---@param layer table Layer implementation
---@param meta table Optional metadata (dependencies, priority, etc.)
function M.register_layer(name, layer, meta)
	meta = meta or {}
	M.layers[name] = {
		impl = layer,
		dependencies = meta.dependencies or {},
		conflicts = meta.conflicts or {},
		priority = meta.priority or 0,
		description = meta.description or "",
	}
end

--- Check if dependencies are satisfied
local function check_dependencies(name)
	local layer_meta = M.layers[name]
	if not layer_meta then return false end

	for _, dep in ipairs(layer_meta.dependencies) do
		if not M.is_active(dep) then
			vim.notify(
				string.format("Layer '%s' requires '%s' to be active", name, dep),
				vim.log.levels.WARN
			)
			return false
		end
	end
	return true
end

--- Check for conflicts
local function check_conflicts(name)
	local layer_meta = M.layers[name]
	if not layer_meta then return false end

	for _, conflict in ipairs(layer_meta.conflicts) do
		if M.is_active(conflict) then
			vim.notify(
				string.format("Layer '%s' conflicts with active layer '%s'", name, conflict),
				vim.log.levels.WARN
			)
			return false
		end
	end
	return true
end

--- Enhanced activation with dependency checking
function M.activate_layer(name, opts)
	local layer_meta = M.layers[name]
	if not layer_meta then
		vim.notify("groundskeeper: layer '" .. name .. "' not found", vim.log.levels.ERROR)
		return false
	end

	-- Check dependencies and conflicts
	if not check_dependencies(name) or not check_conflicts(name) then
		return false
	end

	local layer = layer_meta.impl
	opts = opts or {}

	-- Store config
	M._config[name] = opts

	-- Activate layer
	if type(layer) == "function" then
		layer(opts)
	elseif type(layer.activate) == "function" then
		layer.activate(opts)
	end

	M._active[name] = true

	-- Emit event for other systems to react
	vim.api.nvim_exec_autocmds("User", {
		pattern = "GroundskeeperLayerActivated",
		data = { layer = name, config = opts }
	})

	return true
end

--- Enhanced deactivation
function M.deactivate_layer(name)
	local layer_meta = M.layers[name]
	if not layer_meta then return false end

	local layer = layer_meta.impl

	-- Check if other active layers depend on this one
	for active_name, _ in pairs(M._active) do
		local active_meta = M.layers[active_name]
		if active_meta and vim.tbl_contains(active_meta.dependencies, name) then
			vim.notify(
				string.format("Cannot deactivate '%s': required by active layer '%s'", name, active_name),
				vim.log.levels.WARN
			)
			return false
		end
	end

	if type(layer) == "table" and type(layer.deactivate) == "function" then
		layer.deactivate()
	end

	M._active[name] = nil
	M._config[name] = nil

	-- Emit event
	vim.api.nvim_exec_autocmds("User", {
		pattern = "GroundskeeperLayerDeactivated",
		data = { layer = name }
	})

	return true
end

--- Get active layers sorted by priority
function M.get_active_layers()
	local active = {}
	for name, _ in pairs(M._active) do
		local meta = M.layers[name]
		table.insert(active, {
			name = name,
			priority = meta and meta.priority or 0,
			config = M._config[name] or {}
		})
	end

	table.sort(active, function(a, b) return a.priority > b.priority end)
	return active
end

--- List all registered layers
function M.list_layers()
	local layers = {}
	for name, meta in pairs(M.layers) do
		table.insert(layers, {
			name = name,
			active = M._active[name] ~= nil,
			description = meta.description,
			dependencies = meta.dependencies,
			conflicts = meta.conflicts,
		})
	end
	return layers
end

--- Smart layer switching (deactivate conflicting layers automatically)
function M.switch_to_layer(name, opts)
	local layer_meta = M.layers[name]
	if not layer_meta then return false end

	-- Deactivate conflicting layers
	for _, conflict in ipairs(layer_meta.conflicts) do
		if M.is_active(conflict) then
			M.deactivate_layer(conflict)
		end
	end

	return M.activate_layer(name, opts)
end

--- Existing functions (keeping compatibility)
function M.is_active(name)
	local layer_meta = M.layers[name]
	if not layer_meta then return false end

	local layer = layer_meta.impl
	if type(layer) == "table" and type(layer.is_active) == "function" then
		return layer.is_active()
	end
	return M._active[name] or false
end

function M.toggle_layer(name, opts)
	if M.is_active(name) then
		return M.deactivate_layer(name)
	else
		return M.activate_layer(name, opts)
	end
end

return M
