local M = {}

local state = {
  popup_open = false,
  popup = { win = nil },
  terminal_buf = nil,
}

function M.get()
  return state
end

function M.set_popup_open(v) state.popup_open = v and true or false end

function M.set_popup_win(win)
  state.popup.win = win
end
function M.set_terminal_buf(buf) state.terminal_buf = buf end

return M
