local M = {}

local state = {
	popup_open = false,
	popup = { win = nil },
	terminal_buf = nil,
	base = {
		lhs = {
			open = false,
			type = nil,
			buf = nil,
		},
		main = nil,
	}
}

function M.get()
	return state
end

-- Popup Window
function M.set_popup_open(bool) state.popup_open = bool end
function M.set_popup_win(win) state.popup.win = win end
function M.set_terminal_buf(buf) state.terminal_buf = buf end

-- Base LHS
function M.set_base_lhs_buf(buf) state.base.lhs.buf = buf end
function M.set_base_lhs_type(type) state.base.lhs.type = type end
function M.set_base_lhs_open(bool) state.base.open = bool end

return M
