local core = require("groundskeeper.core")

local M = {}

function M.activate()
	local padding_width = math.floor(vim.api.nvim_win_get_width(0) / 5)
	local scratch_buf = vim.api.nvim_create_buf(true, true)
	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(scratch_buf)
	vim.api.nvim_win_set_width(0, padding_width)
	vim.cmd.wincmd("l")
end

function M.deactivate()

end

core.register_layer("base", M)

return M
