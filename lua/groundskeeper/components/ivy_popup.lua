local st = require("groundskeeper.state")
local state = st.get()

local M = {}

local function create_floating_win(opts)
	opts = opts or {}
	local columns = vim.o.columns
	local width = columns
	local col = 0
	local lines = vim.o.lines
	local height = math.floor(lines * (opts.height_ratio or 0.45))
	local cmdheight = vim.o.cmdheight or 1
	local has_statusline = (vim.o.laststatus or 2) ~= 0
	local status_rows = has_statusline and 1 or 0
	local row = lines - height - cmdheight - status_rows
	if row < 0 then row = 0 end

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "none",
		row = row,
		col = col,
		width = width,
		height = height,
	})
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	return win, buf
end

function M.open(opts)
	opts = opts or {}
	if state.popup_open and state.popup.win and vim.api.nvim_win_is_valid(state.popup.win) then
		return state.popup.win
	end
	-- local win = select(1, create_floating_win(opts))
	local win = select(1, create_floating_win())
	st.set_popup_win(win)
	st.set_popup_open(true)
	return win
end

function M.close()
	if state.popup.win and vim.api.nvim_win_is_valid(state.popup.win) then
		pcall(vim.api.nvim_win_close, state.popup.win, true)
	end
end

function M.toggle(opts)
	if state.popup_open then M.close() else M.open(opts) end
end

return M
