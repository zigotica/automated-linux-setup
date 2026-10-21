local opt = vim.opt

-- Appearance and interaction.
-- True-color support is needed for the custom Nordfox palette.
opt.termguicolors = true
-- Absolute number on the current line, relative distances on surrounding lines.
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.mouse = "a"
-- Ask what to do with unsaved changes instead of silently abandoning them.
opt.confirm = true
-- Indentation: use two spaces; Tab and automatic indentation agree.
opt.autoindent = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
-- Wrap long lines on screen without inserting line breaks into the file.
opt.wrap = true
-- New splits open below or to the right of the current window.
opt.splitbelow = true
opt.splitright = true

-- Search is case-insensitive unless the pattern contains an uppercase letter.
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
-- Preview substitutions in the current buffer while typing :s.
opt.inccommand = "nosplit"
-- :find searches subdirectories; Tab completes matching filenames.
opt.path:append("**")
-- Skip common generated/dependency directories during filename completion.
opt.wildignore:append({ "*/.git/*", "*/node_modules/*", "*/vendor/*" })
opt.wildmenu = true
opt.wildmode = "longest:full,full"

-- One built-in status line for all splits; no status-line plugin is needed.
opt.laststatus = 3
-- Keep the current mode visible because there is no plugin showing it for us.
opt.showmode = true
-- Filename, help/modified/read-only flags, filetype, line:column, file percentage.
-- %= separates left/right sections; %% displays a literal percent sign.
opt.statusline = " %f %h%m%r%=%y %l:%c %p%% "

-- Do not create backup copies or persistent undo files.
-- Normal swap recovery remains enabled in Neovim's default state directory.
opt.backup = false
opt.writebackup = false
opt.undofile = false

-- Use built-in filetype detection, indentation, and syntax highlighting.
-- EditorConfig and commenting are provided by the supported Neovim version.
-- Leave clipboard/register defaults alone: SSH/server sessions may have no
-- system clipboard provider, unlike the development config's unnamedplus.
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")
-- Highlight these languages inside fenced Markdown code blocks.
vim.g.markdown_fenced_languages = { "bash", "json", "lua", "python", "vim", "yaml" }
