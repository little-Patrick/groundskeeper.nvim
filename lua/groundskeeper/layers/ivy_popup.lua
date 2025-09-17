-- Enhanced ivy_popup layer
local core = require("groundskeeper.core")
local state = require("groundskeeper.state")

local M = {}

-- Default configuration
local default_config = {
	component = "file_manager", -- Default component to show
	height_ratio = 0.45,
	width_ratio = 1.0,
}

function M.activate(opts)
	local config = vim.tbl_extend("force", default_config, opts or {})

	-- Store layer config
	state.set_layer_active("ivy_popup", true, config)

	-- Create popup container
	local popup_win = M.create_popup_container(config)
	if not popup_win then
		return false
	end

	-- Load component into popup
	local component_name = config.component
	local component = require("groundskeeper.components." .. component_name)
	component:render_in("popup", config)

	-- Update UI state
	local ui_updates = {
		popup = {
			win = popup_win,
			open = true,
			current_component = component_name
		}
	}
	-- We need a UI state setter function
	state.set_ui_state(ui_updates)

	return true
end

function M.deactivate()
	local ui_state = state.get_ui_state()

	-- Close current component
	if ui_state.popup and ui_state.popup.current_component then
		local component = require("groundskeeper.components." .. ui_state.popup.current_component)
		component:close()
	end

	-- Close popup container
	if ui_state.popup and ui_state.popup.win then
		pcall(vim.api.nvim_win_close, ui_state.popup.win, true)
	end

	-- Update state
	state.set_layer_active("ivy_popup", false)
	state.set_ui_state({
		popup = { win = nil, open = false, current_component = nil }
	})
end

function M.is_active()
	return state.is_layer_active("ivy_popup")
end

function M.toggle(component_name, config)
	if M.is_active() then
		local ui_state = state.get_ui_state()
		-- If same component is active, close it
		if ui_state.popup and ui_state.popup.current_component == component_name then
			M.deactivate()
		else
			-- Switch to new component
			M.switch_component(component_name, config)
		end
	else
		-- Open with specified component
		M.activate({ component = component_name })
	end
end

function M.switch_component(component_name, config)
	if not M.is_active() then
		return M.activate({ component = component_name })
	end

	local ui_state = state.get_ui_state()

	-- Close current component
	if ui_state.popup.current_component then
		local current_component = require("groundskeeper.components." .. ui_state.popup.current_component)
		current_component:close()
	end

	-- Load new component
	local new_component = require("groundskeeper.components." .. component_name)
	new_component:render_in("popup", config)

	-- Update state
	state.set_ui_state({
		popup = { current_component = component_name }
	})
end

function M.create_popup_container(config)
	local columns = vim.o.columns
	local lines = vim.o.lines
	local width = math.floor(columns * (config.width_ratio or 1.0))
	local height = math.floor(lines * (config.height_ratio or 0.45))

	local col = math.floor((columns - width) / 2)
	local row = lines - height - (vim.o.cmdheight or 1) - 1

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		row = row,
		col = col,
		width = width,
		height = height,
	})

	return win
end

-- Register layer
core.register_layer("ivy_popup", M, {
	description = "Ivy-style popup interface for various components",
	conflicts = {},
	priority = 2,
})

return M
