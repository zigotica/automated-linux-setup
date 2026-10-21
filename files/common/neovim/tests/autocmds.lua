local ok, err = pcall(function()
  require("linux.settings")
  require("linux.autocmds")
  local root = vim.fn.tempname()
  vim.fn.mkdir(root .. "/playbooks", "p")

  -- Cover existing files (BufRead) and new files (BufNewFile).
  for _, case in ipairs({
    { "inventory", "yaml.ansible" },
    { "inventory.yml", "yaml.ansible" },
    { "inventory.yaml", "yaml.ansible" },
    { "playbooks/site.yml", "yaml.ansible" },
    { "playbooks/site.yaml", "yaml.ansible" },
    { ".gitlab-ci.yml", "yaml.gitlab" },
    { ".gitlab-ci.yaml", "yaml.gitlab" },
    { "ordinary.yml", "yaml" },
  }) do
    for _, exists in ipairs({ false, true }) do
      local path = root .. "/" .. (exists and "existing-" or "") .. case[1]
      -- Prefix the directory, not the basename, to preserve filetype patterns.
      if exists then
        path = root .. "/existing/" .. case[1]
        vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
        vim.fn.writefile({ "# fixture" }, path)
      end
      vim.cmd.edit(vim.fn.fnameescape(path))
      assert(vim.bo.filetype == case[2], path .. ": " .. vim.bo.filetype)
    end
  end

  -- The original blur behavior saves all modified named buffers, not just one.
  local first = root .. "/first.txt"
  local second = root .. "/second.txt"
  vim.cmd.edit(vim.fn.fnameescape(first))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first" })
  vim.cmd("vsplit " .. vim.fn.fnameescape(second))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "second" })
  vim.api.nvim_exec_autocmds("FocusLost", {})
  assert(vim.fn.readfile(first)[1] == "first")
  assert(vim.fn.readfile(second)[1] == "second")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "window leave" })
  vim.api.nvim_exec_autocmds("WinLeave", {})
  assert(vim.fn.readfile(second)[1] == "window leave")

  -- Reloading the module's file should replace handlers rather than append them.
  local before = #vim.api.nvim_get_autocmds({ group = "LinuxEditing" })
  dofile(vim.api.nvim_get_runtime_file("lua/linux/autocmds.lua", false)[1])
  assert(#vim.api.nvim_get_autocmds({ group = "LinuxEditing" }) == before)
end)

if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
print("Autocommand checks passed")
