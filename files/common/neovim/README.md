# Neovim for Linux administration and everyday editing

A shared configuration targeting Neovim 0.12.x, kept in this repository for Linux desktops and servers. It does not replace the development configuration in tilde.

The user-configuration recipe installs the runtime and copies `init.lua`, `lazy-lock.json`, and `lua/` into the primary user's `~/.config/nvim/`. Documentation and tests are not deployed. Copies overwrite matching files without backups and leave unrelated destination files untouched. lazy.nvim manages the pinned plugins; the runtime upgrade follows the newest stable 0.12.x release through the Ansible Neovim recipe.

```bash
ansible-playbook playbooks/user-config.yml --limit blauet --diff
```

The configuration contains the entry point, editing options, keymaps, theme, and sidebar. The plugins are Nightfox, nvim-tree, and fzf-lua. Nordfox keeps the original custom palette, transparency, inactive-window dimming, and relevant UI overrides. Overrides for removed development plugins are omitted.

lazy.nvim manages the three plugins, as in the development configuration. There is no LSP, AI, completion stack, parser compilation, automatic formatting, or testing integration. File browsing uses nvim-tree, file/content/buffer search uses fzf-lua with fzf and ripgrep, commenting uses `gc`/`gcc`, and the status line uses Neovim's built-in format. Clipboard integration is not forced on machines without a clipboard provider.

`lua/linux/autocmds.lua` contains yank highlighting, save-on-blur, and custom filetypes. Leaving a window or losing application focus saves all writable named modified buffers. Inventory files and YAML under `playbooks/` use `yaml.ansible`; GitLab CI YAML uses `yaml.gitlab`. The latter sets the filetype only and does not install or start a language server.

## Plugin installation

Git and network access are needed on first launch. The configuration bootstraps lazy.nvim and lets it install Nightfox, nvim-tree, and fzf-lua. No separate plugin installation commands are needed. The bootstrap manager revision and all plugin commits are pinned in `lua/linux/plugins.lua`; `lazy-lock.json` records the plugin revisions.

Use `:Lazy` to inspect installation and `:Lazy restore` to restore the lockfile revisions. Automatic update checks and project-local plugin specifications are disabled. No Nerd Font or icon plugin is required.

The sidebar opens automatically with no file or a directory argument, follows the current file, shows dotfiles, and retains the original directory filters. Space m toggles it; `g?` in the sidebar shows default mappings. Custom bulk actions and diagnostics integration are omitted. If nvim-tree fails to load, Space m falls back to netrw.

## Runtime and search executables

The tracked `neovim_series` is configured centrally in `vars/app_versions.yml`, loaded by both the user-configuration and standalone Neovim recipes.

The Ansible recipe tracks `neovim_series: '0.12'`, queries official release tags, and selects the largest stable patch number in that series. It verifies the selected archive's published SHA-256 and extracts the complete runtime into the fixed directory `~/.local/opt/neovim/current/`. The shell profile puts its `bin` directory on PATH directly, without an alias or symlink. Updates replace that installation in place. Debian's packaged executable is left untouched; the previous managed launcher symlink is removed once the new executable exists. Deploy the updated shell profile through the user-configuration recipe and log in again to pick up PATH changes. Old versioned installation directories are not automatically deleted.

```bash
ansible-playbook playbooks/neovim.yml --limit blauet
```

Install the picker tools from Debian packages (sudo required):

```bash
sudo apt install --no-install-recommends fzf ripgrep
```

Both tools are also in the Ansible package list. No compiler, icon plugin, or additional picker extensions are needed.

## Review without replacing an existing configuration

From the Ansible project root:

```bash
nvim -u "$PWD/files/common/neovim/init.lua" -i NONE
```

This selects the repository's init file but still uses normal Neovim data/cache/state paths. It bootstraps lazy.nvim and installs missing plugins in that data directory. Use temporary XDG directories or a separate NVIM_APPNAME for an isolated trial.

## Verification

Headless checks in `tests/smoke.lua` cover the plugin manager, startup, automatic sidebar opening and toggling, the Nordfox palette, basic options, commenting, keymaps, built-in status rendering, the fzf-lua mappings, and native Lua highlighting. Interactive appearance and editing workflow still need user review.

`tests/autocmds.lua` checks filetypes for existing and new files, saves on focus/window loss using temporary fixtures, and checks that reloading the module does not duplicate handlers.

## Keys

Space is the leader. Existing basic editing mappings are retained where they do not require development plugins.

| Key | Action |
| --- | --- |
| Ctrl-S | Save |
| Escape | Clear search highlighting |
| F8 | Toggle British English spelling |
| F9 | Reindent buffer or selection |
| Space m | Toggle the file sidebar (netrw fallback if missing) |
| Space f | Fuzzy file picker |
| Space b | Open-buffer picker |
| Space g | Live content search with ripgrep |
| Space q | Open quickfix search results |
| Space Space r f | Prepare replacement of the word under the cursor throughout the file |
| Space Space r s | Prepare replacement within the selected line range |
| Space Space r b | Prepare replacement across open buffers, saving affected buffers |
| Space Space r p | Prepare replacement once per file in the quickfix list, without saving |
| ]q / [q | Next / previous quickfix result |
| Space j / k | Move a line down / up |
| J / K in visual mode | Move the selection down / up |
| > / < in visual mode | Change indentation and keep the selection |
| gcc / gc with a motion or selection | Built-in commenting |

Search uses the current working directory and ripgrep's default ignore rules, including `.gitignore`. The picker loads on demand. Hidden/ignored files are not included by default; adjust picker options deliberately when needed. Standard registers are retained, rather than the development configuration's delete-register remaps. Persistent undo files and file backups are disabled; Neovim's normal swap recovery remains enabled in its state directory.

Replacement mappings use two leaders and leave the command line open for review and editing before Enter. Selection replacement uses the selected lines, not only the selected columns. Project replacement uses `cfdo` to avoid processing one file repeatedly when it has multiple quickfix entries. `tests/keymaps.lua` checks the four mappings and the once-per-file behavior.
