local st = require("groundskeeper.state")
local state = st.get()

local M = {}

function M.open()
  if state.terminal_buf and vim.api.nvim_buf_is_valid(state.terminal_buf) then
    vim.api.nvim_win_set_buf(0, state.terminal_buf)
    return state.terminal_buf
  end
  vim.cmd("terminal")
	vim.cmd("startinsert")
  local buf = vim.api.nvim_get_current_buf()
  st.set_terminal_buf(buf)
  return buf
end

return M

