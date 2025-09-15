-- Entry point for the Groundskeeper plugin

-- Require the core module to manage layers
local core = require("groundskeeper.core")

-- Require the layer modules to ensure they are registered
require("groundskeeper.layers.base")
require("groundskeeper.layers.layer2")

-- Define commands to activate layers
vim.api.nvim_create_user_command("GroundskeeperBase", function()
    core.activate_layer("base")
end, { desc = "Activate the Base UI layer" })

vim.api.nvim_create_user_command("GroundskeeperLayer2", function()
    core.activate_layer("layer2")
end, { desc = "Activate the Layer 2 UI" })
