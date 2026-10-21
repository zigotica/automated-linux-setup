-- Keep related handlers together and avoid duplicates when reloading this file.
local group = vim.api.nvim_create_augroup("LinuxEditing", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Match the development config: save all writable, named modified buffers when
-- leaving a window or the application. Unwritable/unnamed buffers stay open.
vim.api.nvim_create_autocmd({ "FocusLost", "WinLeave" }, {
  group = group,
  desc = "Save files on blur",
  command = "silent! wall",
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = group,
  desc = "Interpret inventory files as an Ansible inventory",
  pattern = { "inventory", "inventory.yml", "inventory.yaml" },
  callback = function(event)
    vim.bo[event.buf].filetype = "yaml.ansible"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = group,
  desc = "Interpret yml files inside a playbooks folder as Ansible files",
  pattern = { "*/playbooks/*.yml", "*/playbooks/*.yaml" },
  callback = function(event)
    vim.bo[event.buf].filetype = "yaml.ansible"
  end,
})

-- Filetype detection only: this does not install or start gitlab-ci-ls.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = group,
  desc = "Interpret GitLab CI YAML as yaml.gitlab for gitlab-ci-ls",
  pattern = { ".gitlab-ci.yml", ".gitlab-ci.yaml" },
  callback = function(event)
    vim.bo[event.buf].filetype = "yaml.gitlab"
  end,
})
