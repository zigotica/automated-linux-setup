-- Minimal version of the original file-explorer menu, loaded by lazy.nvim.
-- Keep a built-in browser available if plugin installation/loading failed.
local available, tree = pcall(require, "nvim-tree")
if not available then
  vim.notify("nvim-tree is not installed; Space m uses netrw instead.", vim.log.levels.WARN)
  vim.keymap.set("n", "<leader>m", "<cmd>Explore<CR>", { desc = "Browse files with netrw" })
  return
end

-- Disable netrw only when its replacement is available.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

tree.setup({
  -- Refresh when entering the tree instead of maintaining filesystem watchers.
  -- This avoids watcher limits and keeps background work small.
  filesystem_watchers = { enable = false },
  reload_on_bufenter = true,
  -- Reveal the current file as focus changes between editing buffers.
  update_focused_file = { enable = true },
  filters = {
    -- Administration often means editing hidden files, so keep them visible.
    dotfiles = false,
    -- Original filters for generated files and dependency directories.
    custom = { ".ccls-cache", ".repro", ".swc", "node_modules", "vendor", ".DS_Store" },
  },
  -- Fixed-width sidebar with collapsed chains of otherwise empty folders.
  view = { width = 30 },
  renderer = {
    group_empty = true,
    -- No devicons dependency or patched terminal font is required.
    icons = {
      show = { file = false, folder = false, folder_arrow = false, git = false },
    },
  },
  -- This config is for everyday editing, without development diagnostics.
  diagnostics = { enable = false },
})

local api = require("nvim-tree.api")
-- Keep default buffer-local tree mappings; g? inside the sidebar shows help.
vim.keymap.set("n", "<leader>m", api.tree.toggle, { desc = "Toggle file sidebar" })

-- Open on empty startup or an explicit directory argument, not when a file
-- was passed to nvim. An explicit directory becomes the tree's root.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("LinuxFileSidebar", { clear = true }),
  callback = function(data)
    local directory = vim.fn.isdirectory(data.file) == 1
    local empty = data.file == "" and vim.bo[data.buf].buftype == ""
    if directory then
      api.tree.open({ path = data.file })
    elseif empty then
      api.tree.open()
    end
  end,
})
