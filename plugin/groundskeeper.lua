local ok, groundskeeper = pcall(require, "groundskeeper")
if not ok then return end

local core = require("groundskeeper.core")
groundskeeper.setup()

vim.api.nvim_create_user_command("CarlTerm", function()
  local ivy_popup = require("groundskeeper.layers.ivy_popup")
  ivy_popup.toggle("terminal")
end, { desc = "toggle ivy terminal" })

vim.api.nvim_create_user_command("CarlSex", function()
  local ivy_popup = require("groundskeeper.layers.ivy_popup")
  ivy_popup.toggle("file_manager")
end, { desc = "toggle ivy explorer" })

vim.api.nvim_create_user_command("CarlBase", function()
  core.toggle_layer("base")
end, { desc = "toggle base layer" })

-- Toggle the base layer with file manager in LHS
vim.api.nvim_create_user_command("CarlBaseFile", function()
  local base = require("groundskeeper.layers.base")
  base.switch_component("file_manager", { type = "netrw" })
end, { desc = "toggle base lhs (file explorer)" })

-- Test command for debugging LHS scratch buffer
vim.api.nvim_create_user_command("CarlBaseScratch", function()
  local base = require("groundskeeper.layers.base")
  base.switch_component("lhs_content", { type = "scratch", persist_buffer = true })
end, { desc = "toggle base lhs (scratch)" })

vim.keymap.set("n", ",cB", ":CarlBaseFile<cr>", { silent = true, desc = "Toggle base file explorer" })
vim.keymap.set("n", ",cb", ":CarlBase<cr>", {silent = true})
vim.keymap.set("n", ",cs", ":CarlSex<cr>", {silent = true})
vim.keymap.set("n", ",ct", ":CarlTerm<cr>", {silent = true})
vim.keymap.set("n", ",cS", ":CarlBaseScratch<cr>", {silent = true, desc = "Toggle base scratch buffer"})
