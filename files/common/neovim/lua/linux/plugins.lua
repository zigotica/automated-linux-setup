local M = {}

function M.setup(config_dir)
  -- Bootstrap the same manager as the development config, without a distro.
  -- Pin first installation; an existing manager checkout is left in place.
  local manager_commit = "85c7ff3711b730b4030d03144f6db6375044ae82"
  -- stdpath respects XDG_DATA_HOME and NVIM_APPNAME for isolated installations.
  local manager_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not (vim.uv or vim.loop).fs_stat(manager_path) then
    -- First launch needs Git and network access. Avoid downloading file blobs
    -- until needed, then check out the reviewed manager revision explicitly.
    local output = vim.fn.system({
      "git", "clone", "--filter=blob:none", "--branch=stable",
      "https://github.com/folke/lazy.nvim.git", manager_path,
    })
    -- Stop on bootstrap failure rather than hiding an incomplete installation.
    if vim.v.shell_error ~= 0 then
      error("Unable to install lazy.nvim: " .. output)
    end
    output = vim.fn.system({ "git", "-C", manager_path, "checkout", "--detach", manager_commit })
    if vim.v.shell_error ~= 0 then
      error("Unable to pin lazy.nvim: " .. output)
    end
  end
  -- Make require("lazy") available before loading the plugin specifications.
  vim.opt.runtimepath:prepend(manager_path)

  -- Three focused plugins: theme, file sidebar, and search/file/buffer picker.
  -- Explicit commits currently keep installs compatible and reproducible.
  require("lazy").setup({
    {
      "ibhagwan/fzf-lua",
      commit = "c67fadd9a24230417267e4f9068227e093c0be2b",
      -- Load the picker on demand. Debian's fzf and ripgrep provide the tools.
      cmd = "FzfLua",
      lazy = true,
      -- Keep ordinary terminal fonts; no icon plugin is needed.
      opts = { file_icons = false, git_icons = false, color_icons = false },
    },
    {
      "EdenEast/nightfox.nvim",
      commit = "4dacd3f0185a2227bdf3b6c0975a8f0bf87cac9a",
      -- Load colors before other plugins set up their UI highlights.
      priority = 1000,
      config = function()
        require("linux.theme")
      end,
    },
    {
      "nvim-tree/nvim-tree.lua",
      commit = "0142ac30ba84fa6ebf7818b097b2addffed78668",
      -- Configuration runs after this plugin is available on runtimepath.
      config = function()
        require("linux.menu")
      end,
    },
  }, {
    -- Theme and sidebar load at startup; the picker overrides this on demand.
    defaults = { lazy = false },
    -- Keep reviewed revisions with the config. :Lazy restore reapplies them.
    -- Explicit commit pins must also be changed to select newer revisions.
    lockfile = config_dir .. "/lazy-lock.json",
    -- Do not add project-local plugins or background update/reload behavior.
    local_spec = false,
    checker = { enabled = false },
    change_detection = { enabled = false },
    -- Preserve distro runtime paths: Debian ships native parsers in /usr/lib/nvim.
    -- Resetting runtimepath hides them and breaks Lua's built-in ftplugin.
    performance = { rtp = { reset = false } },
  })
end

return M
