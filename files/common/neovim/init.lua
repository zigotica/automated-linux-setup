-- Linux administration/everyday-editing config, separate from the dev setup.
-- Resolve modules beside this init file, including when launched with nvim -u.
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.runtimepath:prepend(config_dir)
-- Set leaders before defining mappings or letting plugins define theirs.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Apply editing defaults first; lazy.nvim then installs/loads the plugins.
require("linux.settings")
require("linux.keymaps")
require("linux.autocmds")
require("linux.plugins").setup(config_dir)
