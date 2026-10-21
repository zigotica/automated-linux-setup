-- Loaded by lazy.nvim after Nightfox is installed.
-- Keep the editor usable if a plugin installation failed.
local available, nightfox = pcall(require, "nightfox")
if not available then
  vim.notify("Nordfox is unavailable; inspect :Lazy for installation errors.", vim.log.levels.WARN)
  return
end

nightfox.setup({
  options = {
    -- Preserve the terminal background and dim windows that are not focused.
    transparent = true,
    dim_inactive = true,
  },
  palettes = {
    -- Original custom Nordfox palette from the development configuration.
    nordfox = {
      red = "#bf5454",
      green = "#97b87b",
      yellow = "#e0bb70",
      blue = "#8caadd",
      magenta = "#a585e6",
      cyan = "#99d7e8",
      orange = "#bf6317",
      pink = "#cf95c0",
      fg0 = "#aba7a7",
      fg1 = "#bdb9b9",
      bg0 = "#252525",
      bg1 = "#303030",
      bg2 = "#404040",
      crust = "#252525",
      black = "#252525",
    },
  },
  groups = {
    nordfox = {
      -- Main windows, floating windows, cursor line, and split separators.
      Normal = { fg = "palette.fg1", bg = "palette.bg1" },
      NormalNC = { fg = "palette.fg0", bg = "palette.bg0" },
      NormalFloat = { bg = "palette.bg0" },
      FloatBorder = { fg = "palette.blue", bg = "palette.blue" },
      CursorLine = { bg = "palette.bg0" },
      WinSeparator = { fg = "palette.bg1", bg = "palette.bg0" },
      -- Preserve the file sidebar's original colors without requiring icons.
      NvimTreeNormal = { fg = "palette.fg1", bg = "palette.crust" },
      NvimTreeRootFolder = { fg = "palette.orange" },
      NvimTreeOpenedFile = { fg = "palette.orange" },
      NvimTreeSpecialFile = { fg = "palette.yellow" },
      -- Diagnostic colors are available without enabling any language server.
      DiagnosticError = { fg = "palette.red" },
      DiagnosticWarn = { fg = "palette.yellow" },
      DiagnosticInfo = { fg = "palette.fg1" },
      DiagnosticHint = { fg = "palette.blue" },
      DiagnosticOk = { fg = "palette.green" },
    },
  },
})

-- Apply only after palette and highlight overrides are registered.
vim.cmd("colorscheme nordfox")
