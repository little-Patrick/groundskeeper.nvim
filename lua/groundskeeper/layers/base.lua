-- Enhanced base layer with new architecture
local core = require("groundskeeper.core")
local state = require("groundskeeper.state")

local M = {}

-- Default configuration
local default_config = {
	padding_ratio = 0.2,
	auto_focus_main = true,
	default_component = "lhs_content",
	component_config = {
		type = "scratch"
	}
}

function M.activate(opts)
	local config = vim.tbl_extend("force", default_config, opts or {})

	-- Store layer config
	state.set_layer_active("base", true, config)

	-- Create LHS container
	local lhs_win = M.create_lhs_container(config)
	if not lhs_win then
		return false
	end

	-- Update UI state BEFORE loading component
	local component_name = config.default_component
	state.set_ui_state({
		lhs = {
			win = lhs_win,
			open = true,
			current_component = component_name
		}
	})

	-- Load component into LHS
	local component = require("groundskeeper.components." .. component_name)
	component:render_in("lhs", config.component_config)

	-- Focus main window if configured
	if config.auto_focus_main then
		vim.cmd.wincmd("l")
	end

	return true
end

function M.deactivate()
	local ui_state = state.get_ui_state()

	-- Close current component
	if ui_state.lhs and ui_state.lhs.current_component then
		local component = require("groundskeeper.components." .. ui_state.lhs.current_component)
		component:close()
	end

	-- Close LHS container
	if ui_state.lhs and ui_state.lhs.win then
		pcall(vim.api.nvim_win_close, ui_state.lhs.win, true)
	end

	-- Update state
	state.set_layer_active("base", false)
	state.set_ui_state({
		lhs = { win = nil, open = false, current_component = nil }
	})
end

function M.is_active()
	return state.is_layer_active("base")
end

function M.toggle(opts)
	if M.is_active() then
		M.deactivate()
	else
		M.activate(opts)
	end
end

function M.switch_component(component_name, config)
	if not M.is_active() then
		return M.activate({ default_component = component_name, component_config = config })
	end

	local ui_state = state.get_ui_state()

	-- Close current component
	if ui_state.lhs.current_component then
		local current_component = require("groundskeeper.components." .. ui_state.lhs.current_component)
		current_component:close()
	end

	-- Load new component
	local new_component = require("groundskeeper.components." .. component_name)
	new_component:render_in("lhs", config)

	-- Update state
	state.set_ui_state({
		lhs = { current_component = component_name }
	})
end

function M.create_lhs_container(config)
	-- Check if already open
	local ui_state = state.get_ui_state()
	if ui_state.lhs and ui_state.lhs.win and vim.api.nvim_win_is_valid(ui_state.lhs.win) then
		return ui_state.lhs.win
	end

	-- Create left split
	vim.cmd("leftabove vsplit")

	-- Calculate width
	local padding = math.floor(vim.o.columns * config.padding_ratio)
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(win, padding)

	return win
end

-- Expose layer configuration
function M.get_config()
	local layer_state = state.get_layer_state("base")
	return layer_state.config or default_config
end

function M.update_config(updates)
	local current_config = M.get_config()
	local new_config = vim.tbl_extend("force", current_config, updates)
	state.set_layer_active("base", M.is_active(), new_config)
end

-- Register layer
core.register_layer("base", M, {
	description = "Centered code view with left sidebar",
	conflicts = {},
	priority = 1,
})

return M
