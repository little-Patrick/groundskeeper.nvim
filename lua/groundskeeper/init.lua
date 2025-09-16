local M = {}

local core = require("groundskeeper.core")

function M.setup(opts)
  opts = opts or {}
  require("groundskeeper.layers.base")
  require("groundskeeper.layers.file")
  require("groundskeeper.layers.terminal")
  if opts.autostart == "base" then
    core.activate_layer("base")
  end
end

return M
