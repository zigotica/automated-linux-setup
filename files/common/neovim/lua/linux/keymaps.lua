local map = vim.keymap.set

-- General editing. Descriptions are also visible through :map and :verbose map.
-- Avoid accidentally entering Ex mode with Shift-Q.
map("n", "Q", "<Nop>", { desc = "Disable Ex mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlighting" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR>", { desc = "Save file" })
-- Spelling is buffer-local. Reindentation uses Neovim's indentation rules,
-- not an external formatter or language server.
map("n", "<F8>", "<cmd>setlocal spell! spelllang=en_gb<CR>", { desc = "Toggle spelling" })
map("n", "<F9>", "gg=G", { desc = "Reindent buffer" })
map("x", "<F9>", "=", { desc = "Reindent selection" })

-- One picker interface for filenames, live content search, and open buffers.
-- Commands let lazy.nvim load fzf-lua only when a picker is first requested.
-- Space m is defined separately by the file-sidebar configuration.
map("n", "<leader>f", "<cmd>FzfLua files<CR>", { desc = "Find files" })
map("n", "<leader>g", "<cmd>FzfLua live_grep<CR>", { desc = "Live content search" })
map("n", "<leader>b", "<cmd>FzfLua buffers<CR>", { desc = "Select buffer" })
-- Quickfix navigation is still available for lists exported from the picker.
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next search result" })
map("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous search result" })
map("n", "<leader>q", "<cmd>copen<CR>", { desc = "Open quickfix results" })

-- Replacement: require two leaders for potentially destructive commands.
-- These prepare the command line for editing; Enter still executes it.
map("n", "<leader><leader>rf", ":%s/<C-r><C-w>//g<Left><Left>", { desc = "[R]eplace word under cursor in [F]ile" })
map("v", "<leader><leader>rs", ":s///g<Left><Left><Left>", { desc = "[R]eplace in [S]election" })
-- Buffer replacement saves changes; quickfix-file replacement leaves them unsaved.
map("n", "<leader><leader>rb", ":bufdo %s/<C-r><C-w>//ge | update<C-Left><C-Left><Left><Left><Left><Left>", { desc = "[R]eplace word under cursor in all open [B]uffers" })
-- cfdo runs once per quickfix file, not once per matching quickfix entry.
map("n", "<leader><leader>rp", ":cfdo %s/<C-r><C-w>//g<Left><Left>", { desc = "[R]eplace word under cursor in [P]roject (requires quickfix buffer)" })

-- Move lines and restore indentation with ==.
map("n", "<leader>k", ":move .-2<CR>==", { desc = "Move line up" })
map("n", "<leader>j", ":move .+1<CR>==", { desc = "Move line down" })
-- '< and '> mark the visual selection; gv reselects it after moving/indenting.
map("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
map("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", ">", ">gv", { desc = "Indent and retain selection" })
map("x", "<", "<gv", { desc = "Outdent and retain selection" })
