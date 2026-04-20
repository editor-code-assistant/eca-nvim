local M = {}

local SEVERITY = {
  [vim.diagnostic.severity.ERROR] = "error",
  [vim.diagnostic.severity.WARN]  = "warning",
  [vim.diagnostic.severity.INFO]  = "information",
  [vim.diagnostic.severity.HINT]  = "hint",
}

local function uri_to_bufnr(uri)
  if not uri or uri == "" then return -1 end
  local path = vim.uri_to_fname(uri)
  return vim.fn.bufnr(path)
end

local function get_diagnostics(params)
  local uri = params.uri
  local bufnr = uri_to_bufnr(uri)
  if bufnr == -1 then return { diagnostics = {} } end
  local raw = vim.diagnostic.get(bufnr)
  local diags = {}
  for _, d in ipairs(raw) do
    table.insert(diags, {
      uri      = uri,
      message  = d.message,
      severity = SEVERITY[d.severity] or "information",
      range = {
        start   = { line = d.lnum,             character = d.col },
        ["end"] = { line = d.end_lnum or d.lnum, character = d.end_col or d.col },
      },
      source = d.source,
      code   = d.code,
    })
  end
  return { diagnostics = diags }
end

function M.handle_request(message)
  if message.method == "editor/getDiagnostics" then
    return get_diagnostics(message.params or {})
  end
  return {}
end

return M
