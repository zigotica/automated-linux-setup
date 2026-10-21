local ok, err = pcall(function()
  vim.g.mapleader = " "
  require("linux.settings")
  require("linux.keymaps")

  local function keys(value)
    return vim.api.nvim_replace_termcodes(value, true, false, true)
  end

  for _, mapping in ipairs({
    { "n", "rf", ":%s/<C-r><C-w>//g<Left><Left>" },
    { "v", "rs", ":s///g<Left><Left><Left>" },
    { "n", "rb", ":bufdo %s/<C-r><C-w>//ge | update<C-Left><C-Left><Left><Left><Left><Left>" },
    { "n", "rp", ":cfdo %s/<C-r><C-w>//g<Left><Left>" },
  }) do
    local rhs = vim.fn.maparg("  " .. mapping[2], mapping[1])
    assert(keys(rhs) == keys(mapping[3]), "Replacement mapping: " .. mapping[2])
    assert(not rhs:lower():find("<cr>", 1, true), "Replacement requires manual confirmation")
  end

  -- Include two quickfix entries for one file. Replacing once per entry would
  -- expand token_new again to token_new_new, which must not happen with cfdo.
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  local first, second = root .. "/first.txt", root .. "/second.txt"
  vim.fn.writefile({ "token token" }, first)
  vim.fn.writefile({ "token" }, second)
  vim.fn.setqflist({
    { filename = first, lnum = 1, col = 1 },
    { filename = first, lnum = 1, col = 7 },
    { filename = second, lnum = 1, col = 1 },
  })
  vim.cmd("cfdo %s/token/token_new/g")
  local first_buffer = vim.fn.bufnr(first)
  local second_buffer = vim.fn.bufnr(second)
  assert(vim.api.nvim_buf_get_lines(first_buffer, 0, 1, false)[1] == "token_new token_new")
  assert(vim.api.nvim_buf_get_lines(second_buffer, 0, 1, false)[1] == "token_new")
  assert(vim.fn.readfile(first)[1] == "token token", "Project replacement does not save automatically")
  assert(vim.fn.readfile(second)[1] == "token", "Project replacement does not save automatically")
end)

if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
print("Replacement keymap checks passed")
