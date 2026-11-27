-- [nfnl] fnl/spec/fennel-extras/reader_spec.fnl
local function load_reader()
  local ok, result = pcall(require, "fennel-extras.reader")
  if ok then
    return result
  else
    return {error = "module missing"}
  end
end
local function read_source(path)
  local ok, result
  local function _2_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_2_)
  if ok then
    return result
  else
    return {error = "read failed", path = path}
  end
end
local function file_paths()
  local paths = {}
  local fnl_files = vim.fn.globpath("fnl", "**/*.fnl", false, true)
  local fnlm_files = vim.fn.globpath("fnl", "**/*.fnlm", false, true)
  for _, path in ipairs(fnl_files) do
    table.insert(paths, path)
  end
  for _, path in ipairs(fnlm_files) do
    table.insert(paths, path)
  end
  return paths
end
local function token_text(tokens)
  local function _4_()
    local tbl_26_ = {}
    local i_27_ = 0
    for _, token in ipairs(tokens) do
      local val_28_ = token.text
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
  return table.concat(_4_())
end
local function token_kinds(tokens)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, token in ipairs(tokens) do
    local val_28_ = token.kind
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function round_trip_scenario()
  local reader = load_reader()
  local failures = {}
  if reader.error then
    for _, path in ipairs(file_paths()) do
      table.insert(failures, path)
    end
  else
    for _, path in ipairs(file_paths()) do
      local source = read_source(path)
      if source.error then
        table.insert(failures, ("read failed: " .. path))
      else
        local ok, parsed
        local function _7_()
          return reader.parse(source)
        end
        ok, parsed = pcall(_7_)
        local token_ok, tokens
        local function _8_()
          return reader.tokenize(source)
        end
        token_ok, tokens = pcall(_8_)
        if (not ok or not token_ok or (nil == parsed) or (nil == tokens) or (source ~= reader["to-string"](parsed)) or (source ~= token_text(tokens))) then
          table.insert(failures, path)
        else
        end
      end
    end
  end
  return failures
end
local function tokenize_scenario(source)
  local reader = load_reader()
  if reader.error then
    return reader
  else
    local ok, result
    local function _12_()
      return reader.tokenize(source)
    end
    ok, result = pcall(_12_)
    if ok then
      return result
    else
      return {error = "tokenize failed"}
    end
  end
end
local function parse_scenario(source)
  local reader = load_reader()
  if reader.error then
    return reader
  else
    local ok, result
    local function _15_()
      return reader.parse(source)
    end
    ok, result = pcall(_15_)
    if ok then
      return result
    else
      return {error = "parse failed"}
    end
  end
end
local function kinds_for(source)
  local tokens = tokenize_scenario(source)
  if tokens.error then
    return tokens
  else
    return token_kinds(tokens)
  end
end
local function nested_kinds()
  local root = parse_scenario("(a [b {:c d}])")
  if root.error then
    return root
  else
    local outer = root.children[1]
    local sequence = outer.children[3]
    local table = sequence.children[3]
    return {outer.kind, sequence.kind, table.kind}
  end
end
local function comment_child_kind()
  local parsed = parse_scenario("(a ;; comment\n)")
  if parsed.error then
    return parsed
  else
    local list_node = parsed.children[1]
    local child = list_node.children[3]
    return child.kind
  end
end
local function fail_closed_scenario(source)
  local reader = load_reader()
  if reader.error then
    return reader
  else
    local ok, result, err
    local function _21_()
      return reader.parse(source)
    end
    ok, result, err = pcall(_21_)
    if not ok then
      return {["value?"] = true, ["has-message"] = false}
    else
      return {["value?"] = (nil ~= result), ["has-message"] = (err and ("string" == type(err.message))), line = (err and err.line), col = (err and err.col)}
    end
  end
end
local function fail_closed_summary(source, include_location_3f)
  local result = fail_closed_scenario(source)
  if result.error then
    return result
  else
    if include_location_3f then
      return {["value?"] = result["value?"], ["has-message"] = result["has-message"], line = result.line, col = result.col}
    else
      return {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    end
  end
end
local function _26_()
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = round_trip_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("all Fennel sources round-trip through parsing and tokenization", _27_)
end
require("plenary.busted").describe("round-trip", _26_)
local function _28_()
  local function _29_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"string"}
    local actual_7_auto = kinds_for("\"a) ; \\\" b\"")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a string containing delimiters, semicolon, and an escaped quote is one string token", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"string"}
    local actual_7_auto = kinds_for("\"line one\nline two\"")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a multi-line string is one string token", _30_)
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"comment", "newline", "open", "symbol", "close"}
    local actual_7_auto = kinds_for(";; comment (\n(a)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a parenthesis in a comment does not open a list", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"prefix", "open", "symbol", "whitespace", "symbol", "whitespace", "symbol", "close"}
    local actual_7_auto = kinds_for("#(+ $1 $2)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("hash prefix is followed by a list", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"prefix", "open", "symbol", "whitespace", "prefix", "symbol", "close"}
    local actual_7_auto = kinds_for("`(foo ,bar)")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("quote and unquote prefixes are preserved", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"symbol", "whitespace", "symbol", "whitespace", "symbol", "whitespace", "symbol", "whitespace", "symbol", "whitespace", "number", "whitespace", "number", "whitespace", "number", "whitespace", "number"}
    local actual_7_auto = kinds_for(":kw a.b:c ?. & ... 0x1F 1e3 1_000 -2.5")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keywords, punctuation symbols, and numbers have their respective kinds", _34_)
  local function _35_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "comment"
    local actual_7_auto = comment_child_kind()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a comment before a close delimiter is a child of that list", _35_)
  local function _36_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"comment", "newline", "symbol"}
    local actual_7_auto = kinds_for("#!/usr/bin/env fennel\nfoo")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a leading shebang line is one comment token", _36_)
  local function _37_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"list", "sequence", "table"}
    local actual_7_auto = nested_kinds()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("nested delimiters produce list, sequence, and table nodes", _37_)
end
require("plenary.busted").describe("structure", _28_)
local function _38_()
  local function _39_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, line = 2, col = 5, ["value?"] = false}
    local actual_7_auto = fail_closed_summary("(ok)\n    )", true)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an extra close delimiter returns an error at line 2 column 5", _39_)
  local function _40_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = fail_closed_summary("(missing")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a missing close delimiter returns an error", _40_)
  local function _41_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = fail_closed_summary("\"unterminated")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an unterminated string returns an error", _41_)
  local function _42_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = fail_closed_summary("@foo")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("at-sign reader syntax returns an error", _42_)
  local function _43_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = fail_closed_summary(",@foo")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("comma-at reader syntax returns an error", _43_)
  local function _44_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = fail_closed_summary("foo\tbar")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a tab outside strings and comments returns an error", _44_)
  local function _45_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = fail_closed_summary("foo\r\nbar")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("carriage-return line endings return an error", _45_)
  local function _46_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = fail_closed_summary("\"\\\r\"")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an escaped carriage return inside a string returns an error", _46_)
end
return require("plenary.busted").describe("fail-closed", _38_)
