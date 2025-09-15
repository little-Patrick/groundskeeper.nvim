-- Core module for managing UI layers

local M = {}

-- Table to store layer activation functions
M.layers = {}

-- Function to register a layer
function M.register_layer(name, activate_fn)
    M.layers[name] = activate_fn
end

-- Function to activate a layer
function M.activate_layer(name)
    if M.layers[name] then
        M.layers[name]()
    else
        vim.api.nvim_err_writeln("Layer '" .. name .. "' not found.")
    end
end

return M
