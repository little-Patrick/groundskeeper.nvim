-- Layer 2: File in the center, file manager on the left, terminal at the bottom

local core = require("groundskeeper.core")

local function activate()
    -- Set up the layout
    vim.cmd("tabnew") -- Open a new tab
    vim.cmd("only")   -- Close all other windows in the tab

    -- Open the file manager on the left
    vim.cmd("vsplit")
    vim.cmd("wincmd H")
    vim.cmd("Ex") -- Open the file explorer (netrw or similar plugin)

    -- Open a terminal at the bottom
    vim.cmd("split")
    vim.cmd("wincmd J")
    vim.cmd("terminal")

    -- Focus back to the main file window
    vim.cmd("wincmd k")
end

-- Register Layer 2
core.register_layer("layer2", activate)
