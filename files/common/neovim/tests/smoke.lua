local ok, err = pcall(function()
  assert(vim.fn.has("nvim-0.12") == 1, "Tests target the configured Neovim 0.12 series or newer")
  assert(vim.opt.shiftwidth:get() == 2)
  assert(vim.opt.expandtab:get())
  assert(not vim.opt.backup:get() and not vim.opt.writebackup:get())
  assert(not vim.opt.undofile:get())
  assert(vim.opt.clipboard:get()[1] == nil, "No forced clipboard provider")
  local menu = vim.fn.maparg("<Space>m", "n", false, true)
  assert(menu.desc ~= nil, "File browser mapping is available")
  if vim.env.NVIM_LINUX_EXPECT_TREE == "1" then
    local api = require("nvim-tree.api")
    assert(menu.desc == "Toggle file sidebar")
    assert(api.tree.is_visible(), "Sidebar opens when starting without a file")
    menu.callback()
    assert(not api.tree.is_visible(), "Space m closes the sidebar")
    menu.callback()
    assert(api.tree.is_visible(), "Space m reopens the sidebar")
    api.tree.close()
  end
  assert(vim.fn.maparg("gcc", "n") ~= "", "Built-in commenting is available")
  assert(package.loaded.lazy ~= nil, "lazy.nvim manages the plugins")
  assert(package.loaded.lspconfig == nil, "No development LSP setup")

  local status = vim.api.nvim_eval_statusline(vim.opt.statusline:get(), {})
  assert(type(status.str) == "string")

  if vim.env.NVIM_LINUX_EXPECT_THEME == "1" then
    assert(vim.g.colors_name == "nordfox", "Original theme must load")
    local palette = require("nightfox.palette").load("nordfox")
    assert(palette.red.base == "#bf5454", "Original palette must be preserved")
  end

  -- The three navigation mappings use one maintained picker, not a custom scan.
  assert(vim.fn.maparg("<Space>f", "n") == "<Cmd>FzfLua files<CR>")
  assert(vim.fn.maparg("<Space>g", "n") == "<Cmd>FzfLua live_grep<CR>")
  assert(vim.fn.maparg("<Space>b", "n") == "<Cmd>FzfLua buffers<CR>")
  if vim.env.NVIM_LINUX_EXPECT_SEARCH == "1" then
    assert(vim.fn.executable("fzf") == 1, "Install Debian's fzf package")
    assert(vim.fn.executable("rg") == 1, "Install Debian's ripgrep package")
    require("lazy").load({ plugins = { "fzf-lua" } })
    assert(type(require("fzf-lua").live_grep) == "function")
  end

  -- Opening a real Lua file must reach Debian's bundled Tree-sitter parser.
  -- An empty startup buffer alone would miss a broken runtime search path.
  vim.cmd("edit init.lua")
  assert(vim.bo.filetype == "lua")
  assert(#vim.api.nvim_get_runtime_file("parser/lua.*", true) > 0, "Bundled Lua parser is visible")
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil,
    "Native Lua highlighting is active")
end)

if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
print("Minimal configuration smoke checks passed")
