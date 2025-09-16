local st = require("groundskeeper.state")
local state = st.get()

local M = {}

function M.open(opts)
	opts = opts or {}
	local padding_width = math.floor(vim.api.nvim_win_get_width(0) / 5)
	local scratch_buf = vim.api.nvim_create_buf(true, true)
	vim.cmd("vsplit")
	if state.base.lhs == nil then
		vim.api.nvim_set_current_buf(scratch_buf)
		vim.api.nvim_win_set_width(0, padding_width)
		vim.cmd.wincmd("l")
	end
  if state.base.type == "file" then

    return state.terminal_buf
	end
	if state.base.buf then
		-- do something
		return
	end
  vim.cmd("terminal")
	vim.cmd("startinsert")
  local buf = vim.api.nvim_get_current_buf()
  st.set_terminal_buf(buf)
  return buf
end

return M
