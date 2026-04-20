local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    post_once = child.stop,
  },
})

T["editor"] = MiniTest.new_set()

T["editor"]["returns empty diagnostics when buffer not found"] = function()
  local count = child.lua_get([[
    require("eca.editor").handle_request({
      method = "editor/getDiagnostics",
      params = { uri = "file:///nonexistent/file.lua" },
    }).diagnostics
  ]])
  eq(#count, 0)
end

T["editor"]["maps severity levels correctly"] = function()
  child.lua([[
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "/tmp/eca_test_sev.lua")
    local ns = vim.api.nvim_create_namespace("eca_sev")
    vim.diagnostic.set(ns, bufnr, {
      { lnum=0, col=0, end_lnum=0, end_col=1, message="err",  severity=vim.diagnostic.severity.ERROR },
      { lnum=1, col=0, end_lnum=1, end_col=1, message="warn", severity=vim.diagnostic.severity.WARN  },
      { lnum=2, col=0, end_lnum=2, end_col=1, message="info", severity=vim.diagnostic.severity.INFO  },
      { lnum=3, col=0, end_lnum=3, end_col=1, message="hint", severity=vim.diagnostic.severity.HINT  },
    })
    local res = require("eca.editor").handle_request({
      method = "editor/getDiagnostics",
      params = { uri = "file:///tmp/eca_test_sev.lua" },
    })
    _G.sev_result = {}
    for _, d in ipairs(res.diagnostics) do
      table.insert(_G.sev_result, d.severity)
    end
    vim.api.nvim_buf_delete(bufnr, { force = true })
  ]])
  eq(child.lua_get("_G.sev_result[1]"), "error")
  eq(child.lua_get("_G.sev_result[2]"), "warning")
  eq(child.lua_get("_G.sev_result[3]"), "information")
  eq(child.lua_get("_G.sev_result[4]"), "hint")
end

T["editor"]["includes range and message fields"] = function()
  child.lua([[
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "/tmp/eca_test_fields.lua")
    local ns = vim.api.nvim_create_namespace("eca_fields")
    vim.diagnostic.set(ns, bufnr, {
      { lnum=5, col=3, end_lnum=5, end_col=10, message="test error", severity=vim.diagnostic.severity.ERROR, source="myls" },
    })
    local res = require("eca.editor").handle_request({
      method = "editor/getDiagnostics",
      params = { uri = "file:///tmp/eca_test_fields.lua" },
    })
    _G.field_result = res.diagnostics[1]
    vim.api.nvim_buf_delete(bufnr, { force = true })
  ]])
  eq(child.lua_get("_G.field_result.message"), "test error")
  eq(child.lua_get("_G.field_result.range.start.line"), 5)
  eq(child.lua_get("_G.field_result.range.start.character"), 3)
  eq(child.lua_get([[_G.field_result.range["end"].line]]), 5)
  eq(child.lua_get([[_G.field_result.range["end"].character]]), 10)
end

T["editor"]["falls back to information for unknown severity"] = function()
  child.lua([[
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "/tmp/eca_test_fallback.lua")
    local ns = vim.api.nvim_create_namespace("eca_fallback")
    vim.diagnostic.set(ns, bufnr, {
      { lnum=0, col=0, end_lnum=0, end_col=1, message="x", severity=99 },
    })
    local res = require("eca.editor").handle_request({
      method = "editor/getDiagnostics",
      params = { uri = "file:///tmp/eca_test_fallback.lua" },
    })
    _G.fallback_sev = res.diagnostics[1] and res.diagnostics[1].severity
    vim.api.nvim_buf_delete(bufnr, { force = true })
  ]])
  eq(child.lua_get("_G.fallback_sev"), "information")
end

T["editor"]["uri field is present on each diagnostic"] = function()
  child.lua([[
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "/tmp/eca_test_uri.lua")
    local ns = vim.api.nvim_create_namespace("eca_uri")
    vim.diagnostic.set(ns, bufnr, {
      { lnum=0, col=0, end_lnum=0, end_col=1, message="e1", severity=vim.diagnostic.severity.ERROR },
      { lnum=1, col=0, end_lnum=1, end_col=1, message="e2", severity=vim.diagnostic.severity.WARN  },
    })
    local res = require("eca.editor").handle_request({
      method = "editor/getDiagnostics",
      params = { uri = "file:///tmp/eca_test_uri.lua" },
    })
    _G.uri_result = {}
    for _, d in ipairs(res.diagnostics) do
      table.insert(_G.uri_result, d.uri)
    end
    vim.api.nvim_buf_delete(bufnr, { force = true })
  ]])
  eq(child.lua_get("_G.uri_result[1]"), "file:///tmp/eca_test_uri.lua")
  eq(child.lua_get("_G.uri_result[2]"), "file:///tmp/eca_test_uri.lua")
end

T["editor"]["returns empty table for unknown method"] = function()
  local count = child.lua_get([[
    vim.tbl_count(require("eca.editor").handle_request({ method = "editor/unknown", params = {} }))
  ]])
  eq(count, 0)
end

return T
