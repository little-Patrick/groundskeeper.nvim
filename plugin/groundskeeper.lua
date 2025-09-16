local ok, groundskeeper = pcall(require, "groundskeeper")
if not ok then return end

local core = require("groundskeeper.core")
groundskeeper.setup()

vim.api.nvim_create_user_command("CarlTerm", function()
  core.activate_layer("ivy_terminal")
end, { desc = "activate ivy terminal" })

vim.api.nvim_create_user_command("SexWithCarl", function()
  core.activate_layer("ivy_file")
end, { desc = "activate ivy explorer" })

vim.api.nvim_create_user_command("CarlBase", function()
  core.activate_layer("base")
end, { desc = "activate base" })

vim.keymap.set("n", ",cb", ":CarlBase<cr>", {silent = true})
vim.keymap.set("n", ",cs", ":SexWithCarl<cr>", {silent = true})
vim.keymap.set("n", ",ct", ":CarlTerm<cr>", {silent = true})
