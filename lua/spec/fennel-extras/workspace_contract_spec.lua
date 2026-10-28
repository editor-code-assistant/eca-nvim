-- [nfnl] fnl/spec/fennel-extras/workspace_contract_spec.fnl
local config = require("fennel-extras.config")
local function write_file(path, text)
  local file = assert(io.open(path, "w"))
  file:write(text)
  file:close()
  return path
end
local function run_cli(root, args)
  local lines = {}
  local cli = require("fennel-extras.cli")
  local function _1_(line)
    return table.insert(lines, line)
  end
  return {code = cli.run(args, {cwd = root, print = _1_}), lines = lines}
end
local function validation(value)
  local ok, result, error = pcall(config.validate, value)
  return {ok = (ok and result), value = result, error = error}
end
local function error_message(result)
  local error = result.error
  if ("table" == type(error)) then
    return error.message
  else
    return error
  end
end
local function legacy_config(key)
  local value
  if (key == "extensions") then
    value = {".fnl"}
  else
    if ((key == "dotfiles") or (key == "symlinks")) then
      value = false
    else
      value = {"fnl"}
    end
  end
  local result = {}
  result[key] = value
  return result
end
local workspace_config = {workspace = {paths = {"fnl"}, exclude = {"fnl/generated"}, extensions = {".fnl", ".fnlm"}, dotfiles = false, symlinks = false}, format = {["indent-width"] = 2, builtins = false, parser = false, ["prefix-fallbacks"] = false}, lint = {rules = {}}}
local function _5_()
  local function _6_()
    local result = validation(workspace_config)
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and result.value)
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (. result \"value\"))")
    return true
  end
  require("plenary.busted").it("root configuration is grouped under workspace, format, and lint", _6_)
  local function _7_()
    local result = validation(workspace_config)
    local value = result.value
    local assert_28_auto = require("luassert")
    local value_29_auto = (result.ok and vim.deep_equal({"fnl"}, value.workspace.paths) and vim.deep_equal({"fnl/generated"}, value.workspace.exclude) and vim.deep_equal({".fnl", ".fnlm"}, value.workspace.extensions) and (false == value.workspace.dotfiles) and (false == value.workspace.symlinks))
    assert_28_auto.is_truthy(value_29_auto, "(and (. result \"ok\") (vim.deep_equal [\"fnl\"] (. value \"workspace\" \"paths\")) (vim.deep_equal [\"fnl/generated\"] (. value \"workspace\" \"exclude\")) (vim.deep_equal [\".fnl\" \".fnlm\"] (. value \"workspace\" \"extensions\")) (= false (. value \"workspace\" \"dotfiles\")) (= false (. value \"workspace\" \"symlinks\")))")
    return true
  end
  require("plenary.busted").it("workspace owns path and scan settings", _7_)
  local function _8_()
    for _, key in ipairs({"paths", "exclude", "dotfiles", "symlinks"}) do
      local result = validation(legacy_config(key))
      local assert_28_auto = require("luassert")
      local value_29_auto = (not result.ok and (("unknown configuration key: " .. key) == error_message(result)))
      assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= (.. \"unknown configuration key: \" key) (error-message result)))")
    end
    return nil
  end
  require("plenary.busted").it("old root-level path and scan settings are rejected", _8_)
  local function _9_()
    for _, key in ipairs({"skip-dotfiles", "follow-symlinks"}) do
      local result = validation(legacy_config(key))
      local assert_28_auto = require("luassert")
      local value_29_auto = (not result.ok and (("unknown configuration key: " .. key) == error_message(result)))
      assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= (.. \"unknown configuration key: \" key) (error-message result)))")
    end
    return nil
  end
  require("plenary.busted").it("root-level scan aliases are rejected", _9_)
  local function _10_()
    local result = validation(legacy_config("extensions"))
    local assert_28_auto = require("luassert")
    local value_29_auto = result.ok
    assert_28_auto.is_truthy(value_29_auto, "(. result \"ok\")")
    return true
  end
  return require("plenary.busted").it("root-level extensions remain accepted for format compatibility", _10_)
end
require("plenary.busted").describe("workspace-root-contract", _5_)
local function _11_()
  local function _12_()
    local root = vim.fn.tempname()
    local config0 = (root .. "/.fnl-extras.fnl")
    local path = (root .. "/fnl/spec/example.fnl")
    local text = "{:workspace {:paths [\"fnl\"] :exclude [] :extensions [\".fnl\"] :dotfiles false :symlinks false} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {:forbidden-form [{:severity :warning :applies-to {:files [\"^fnl/spec/\"]} :options {:forms [\"var\" \"set\" \"while\"]} :exclusions []}]}}}"
    local _ = vim.fn.mkdir((root .. "/fnl/spec"), "p")
    local _0 = vim.fn.mkdir((root .. "/.git"), "p")
    local _1 = write_file(config0, text)
    local _2 = write_file(path, "(var x 1)\\n")
    local result = run_cli(root, {"lint", "--all"})
    vim.fn.delete(root, "rf")
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = result.code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("a workspace path makes rule file patterns workspace-relative", _12_)
end
require("plenary.busted").describe("workspace-relative-rule-files", _11_)
local function _13_()
  local function _14_()
    local value = {lint = {rules = {["forbidden-form"] = {{severity = "warning", ["applies-to"] = {contexts = {"source"}}, options = {forms = {"var", "set", "while"}}, exclusions = {}}}}}}
    local result = validation(value)
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and ("unknown applies-to key: contexts" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= \"unknown applies-to key: contexts\" (error-message result)))")
    return true
  end
  require("plenary.busted").it("contexts is not a public applies-to selector", _14_)
  local function _15_()
    local result = validation({lint = {["spec-files"] = {"^spec/"}, rules = {}}})
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result.ok and ("unknown lint key: spec-files" == error_message(result)))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"ok\")) (= \"unknown lint key: spec-files\" (error-message result)))")
    return true
  end
  return require("plenary.busted").it("spec-files is not a public lint setting", _15_)
end
return require("plenary.busted").describe("workspace-public-contract-rejections", _13_)
