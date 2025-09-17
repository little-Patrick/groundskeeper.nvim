local M = {}

local core = require("groundskeeper.core")
local layout = require("groundskeeper.layout")

-- Default plugin configuration
local default_config = {
	-- Auto-start behavior
	autostart = nil, -- "base", "lsp_nav", "debug", etc.

	-- Default layer configurations
	layers = {
		base = {
			padding_ratio = 0.2,
			auto_focus_main = true,
			default_component = "lhs_content",
		},
		ivy_popup = {
			height_ratio = 0.45,
			width_ratio = 1.0,
			default_component = "file_manager",
		}
	},

	-- Default component configurations
	components = {
		file_manager = {
			type = "netrw", -- "netrw", "telescope", "oil"
			follow_current = true,
			show_hidden = false,
		},
		terminal = {
			shell = nil, -- use default shell
			persist_session = true,
			start_insert = true,
		},
		lhs_content = {
			type = "scratch", -- "scratch", "file", "symbols"
			auto_focus = false,
		}
	},

	-- Layout presets
	layouts = {
		-- User can override or add custom layouts here
	},

	-- Keymaps
	keymaps = {
		enable_default = true,
		prefix = ",c", -- Default prefix for groundskeeper commands
		mappings = {
			toggle_base = "b",
			toggle_ivy_popup = "p",
			ivy_file_manager = "f",
			ivy_terminal = "t",
			switch_layout = "l",
		}
	},

	-- Integration settings
	integrations = {
		telescope = {
			enabled = false,
			ivy_theme = true,
			replace_file_manager = true, -- Use telescope instead of netrw
		},
		dap = {
			enabled = false,
			auto_setup = true,
		},
		lsp = {
			enabled = true,
			auto_setup = true,
		}
	}
}

function M.setup(user_config)
	-- Merge user config with defaults
	local config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- Store config globally for access by layers/components
	_G.groundskeeper_config = config

	-- Register built-in layers
	M.register_builtin_layers(config)

	-- Register custom layouts
	for name, layout_spec in pairs(config.layouts) do
		layout.register_preset(name, layout_spec)
	end

	-- Setup keymaps
	if config.keymaps.enable_default then
		M.setup_keymaps(config.keymaps)
	end

	-- Setup integrations
	M.setup_integrations(config.integrations)

	-- Auto-start if specified
	if config.autostart then
		if layout.get_presets()[config.autostart] then
			layout.switch_to_preset(config.autostart)
		else
			core.activate_layer(config.autostart, config.layers[config.autostart])
		end
	end

	-- Setup autocmds for session management
	M.setup_autocmds()
end

function M.register_builtin_layers(config)
	-- Load and register all layer modules
	require("groundskeeper.layers.base")
	require("groundskeeper.layers.ivy_popup")

	-- Register with dependencies and metadata
	core.register_layer("base", require("groundskeeper.layers.base"), {
		description = "Centered code view with left sidebar",
		conflicts = {},
		priority = 1,
	})

	core.register_layer("ivy_popup", require("groundskeeper.layers.ivy_popup"), {
		description = "Ivy-style popup interface for various components",
		conflicts = {},
		priority = 2,
	})
end

function M.setup_keymaps(keymap_config)
	local prefix = keymap_config.prefix
	local mappings = keymap_config.mappings

	-- Create user commands
	vim.api.nvim_create_user_command("GroundskeeperToggleBase", function()
		core.toggle_layer("base")
	end, { desc = "Toggle base layer" })

	vim.api.nvim_create_user_command("GroundskeeperToggleIvyPopup", function()
		core.toggle_layer("ivy_popup")
	end, { desc = "Toggle ivy popup layer" })

	vim.api.nvim_create_user_command("GroundskeeperIvyFileManager", function()
		local ivy_popup = require("groundskeeper.layers.ivy_popup")
		ivy_popup.switch_component("file_manager")
	end, { desc = "Open file manager in ivy popup" })

	vim.api.nvim_create_user_command("GroundskeeperIvyTerminal", function()
		local ivy_popup = require("groundskeeper.layers.ivy_popup")
		ivy_popup.switch_component("terminal")
	end, { desc = "Open terminal in ivy popup" })

	vim.api.nvim_create_user_command("GroundskeeperSwitchLayout", function(opts)
		local preset_name = opts.args
		if preset_name == "" then
			-- Show available presets
			local presets = layout.get_presets()
			vim.notify("Available layouts: " .. table.concat(presets, ", "), vim.log.levels.INFO)
		else
			layout.switch_to_preset(preset_name)
		end
	end, {
		nargs = "?",
		complete = function() return layout.get_presets() end,
		desc = "Switch to layout preset"
	})

	-- Set up keymaps if mappings are provided
	if mappings.toggle_base then
		vim.keymap.set("n", prefix .. mappings.toggle_base, ":GroundskeeperToggleBase<CR>",
			{ silent = true, desc = "Toggle base layer" })
	end

	if mappings.toggle_ivy_popup then
		vim.keymap.set("n", prefix .. mappings.toggle_ivy_popup, ":GroundskeeperToggleIvyPopup<CR>",
			{ silent = true, desc = "Toggle ivy popup layer" })
	end

	if mappings.ivy_file_manager then
		vim.keymap.set("n", prefix .. mappings.ivy_file_manager, ":GroundskeeperIvyFileManager<CR>",
			{ silent = true, desc = "Open file manager in ivy popup" })
	end

	if mappings.ivy_terminal then
		vim.keymap.set("n", prefix .. mappings.ivy_terminal, ":GroundskeeperIvyTerminal<CR>",
			{ silent = true, desc = "Open terminal in ivy popup" })
	end

	if mappings.switch_layout then
		vim.keymap.set("n", prefix .. mappings.switch_layout, ":GroundskeeperSwitchLayout ",
			{ desc = "Switch layout preset" })
	end
end

function M.setup_integrations(integrations)
	-- Telescope integration
	if integrations.telescope.enabled then
		M.setup_telescope_integration(integrations.telescope)
	end

	-- DAP integration (for later)
	if integrations.dap.enabled then
		M.setup_dap_integration(integrations.dap)
	end

	-- LSP integration (for later)
	if integrations.lsp.enabled then
		M.setup_lsp_integration(integrations.lsp)
	end
end

function M.setup_telescope_integration(telescope_config)
	local has_telescope, telescope = pcall(require, "telescope")
	if not has_telescope then
		vim.notify("Telescope not found, skipping integration", vim.log.levels.WARN)
		return
	end

	if telescope_config.replace_file_manager then
		-- Update component configuration to use telescope
		local config = _G.groundskeeper_config
		if config and config.components and config.components.file_manager then
			config.components.file_manager.type = "telescope"
			config.components.file_manager.theme = telescope_config.ivy_theme and "ivy" or "default"
		end
	end
end

function M.setup_dap_integration(dap_config)
	-- Placeholder for DAP integration
	-- This would set up debug layouts and DAP UI integration
end

function M.setup_lsp_integration(lsp_config)
	-- Placeholder for LSP integration
	-- This would set up LSP-focused layouts and symbol navigation
end

function M.setup_autocmds()
	local augroup = vim.api.nvim_create_augroup("Groundskeeper", { clear = true })

	-- Save/restore layout on session management
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = function()
			-- Could save current layout to session file
		end,
	})

	-- Clean up resources
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = function()
			-- Clean up any resources, close terminals, etc.
		end,
	})
end

-- Utility functions for users
function M.get_config()
	return _G.groundskeeper_config or {}
end

function M.get_active_layers()
	return core.get_active_layers()
end

function M.list_layers()
	return core.list_layers()
end

return M
