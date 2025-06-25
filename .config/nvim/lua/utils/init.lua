local M = {}

function M.deep_merge_opts(base, user)
  local result = vim.deepcopy(base or {})
  for k, v in pairs(user or {}) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = vim.tbl_deep_extend("force", result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

function M.debug_table(label, tbl)
  vim.notify(label .. ":\n" .. vim.inspect(tbl), vim.log.levels.INFO)
end

function M.debug_catppuccin()
  local ok, cp = pcall(require, "catppuccin")
  if not ok then
    vim.notify("catppuccin not loaded", vim.log.levels.ERROR)
    return
  end

  local config = vim.deepcopy(cp.options or vim.g.catppuccin_options or {})
  config.flavour = vim.g.catppuccin_flavour or config.flavour or "N/A"

  local lines = { "Catppuccin Config:" }
  for k, v in pairs(config) do
    table.insert(lines, string.format("%s = %s", k, vim.inspect(v)))
  end

  vim.cmd("new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

return M
