-- Base layer: A "no-neck-pain"-like layout

local core = require("groundskeeper.core")

local function activate()
    -- Set up the base layout
    vim.cmd("only")   -- Close all other windows in the tab

    -- Add padding on either side
    vim.cmd("vsplit")
    vim.cmd("wincmd L")
    vim.cmd("vsplit")
    vim.cmd("wincmd H")

    -- Resize padding windows
    vim.cmd("vertical resize 30") -- Left padding
    vim.cmd("wincmd l")
    vim.cmd("vertical resize 30") -- Right padding
    vim.cmd("wincmd h")
end

-- Register the base layer
core.register_layer("base", activate)
