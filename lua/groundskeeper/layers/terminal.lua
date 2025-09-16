local core = require("groundskeeper.core")
local popup = require("groundskeeper.components.ivy_popup")
local term = require("groundskeeper.components.terminal")
local st = require("groundskeeper.state")
local state = st.get()

local M = {}

function M.activate()
  local win = select(1, popup.open())
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    term.open()
  end
end

function M.deactivate()
  popup.close()
end

function M.is_active() return state.popup_open end

function M.toggle()
  if state.popup_open then M.deactivate() else M.activate() end
end


core.register_layer("ivy_terminal", M)

return M

