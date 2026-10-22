-- [nfnl] fnl/spec/fennel-extras/format_spec.fnl
local function load_format()
  local ok, result = pcall(require, "fennel-extras.format")
  if ok then
    return result
  else
    return {error = "module missing"}
  end
end
local function load_parser()
  local ok, result = pcall(require, "eca.nfnl.fennel")
  if ok then
    return result
  else
    return {error = "parser module missing"}
  end
end
local function verifier_scenario()
  local format = load_format()
  local parser = load_parser()
  local same_a = "(when x\ny)"
  local same_b = "(when x\n  y)"
  local symbol_a = "(when x\ny)"
  local symbol_b = "(when z\ny)"
  local comment_a = ";; one\n(foo)"
  local comment_b = ";; two\n(foo)"
  local second_a = "(a)\n(b)"
  local second_b = "(a)\n(c)"
  local _3_
  if format.error then
    _3_ = false
  else
    _3_ = format["indent-only?"](same_a, same_b)
  end
  local _5_
  if format.error then
    _5_ = true
  else
    _5_ = format["indent-only?"]("(foo \"a\")", "(foo \"b\")")
  end
  local _7_
  if format.error then
    _7_ = true
  else
    _7_ = format["indent-only?"]("(foo)", "(foo) ")
  end
  local _9_
  if format.error then
    _9_ = true
  else
    _9_ = format["indent-only?"]("(foo)\n(bar)", "(foo)")
  end
  local _11_
  if format.error then
    _11_ = true
  else
    _11_ = format["indent-only?"]("(foo)", "(bar)")
  end
  local _13_
  if format.error then
    _13_ = false
  else
    _13_ = format["indent-only?"]("(let [a 1\n      long-name 2])", "(let [a         1\n      long-name 2])", true)
  end
  local _15_
  if format.error then
    _15_ = true
  else
    _15_ = format["indent-only?"]("(let [a 1\n      long-name 2])", "(let [a1\n      long-name 2])", true)
  end
  local _17_
  if format.error then
    _17_ = true
  else
    _17_ = format["indent-only?"]("(let [x \"a b\"])", "(let [x \"a  b\"])", true)
  end
  local _19_
  if format.error then
    _19_ = true
  else
    _19_ = format["indent-only?"]("(let [a 1\n b 2])", "(let [a 1 b 2])", true)
  end
  local _21_
  if format.error then
    _21_ = false
  else
    _21_ = format["indent-only?"]("(let [a 1 b 2])", "(let [a 1\n      b 2])", true)
  end
  local _23_
  if format.error then
    _23_ = true
  else
    _23_ = format["indent-only?"]("(f a\n\n  b)", "(f a\n  b)", true)
  end
  local _25_
  if format.error then
    _25_ = false
  else
    _25_ = format["indent-only?"]("(f a    b)", "(f a b)", true)
  end
  local _27_
  if format.error then
    _27_ = true
  else
    _27_ = format["indent-only?"]("(f a b)", "(f ab)", true)
  end
  local _29_
  if (format.error or parser.error) then
    _29_ = false
  else
    _29_ = format["ast-equal?"](parser, same_a, same_b)
  end
  local _31_
  if (format.error or parser.error) then
    _31_ = true
  else
    _31_ = format["ast-equal?"](parser, symbol_a, symbol_b)
  end
  local _33_
  if (format.error or parser.error) then
    _33_ = true
  else
    _33_ = format["ast-equal?"](parser, comment_a, comment_b)
  end
  local _35_
  if (format.error or parser.error) then
    _35_ = true
  else
    _35_ = format["ast-equal?"](parser, second_a, second_b)
  end
  return {["indent-same"] = _3_, ["indent-string"] = _5_, ["indent-trailing"] = _7_, ["indent-lines"] = _9_, ["indent-char"] = _11_, ["binding-aligned"] = _13_, ["binding-joined"] = _15_, ["binding-string"] = _17_, ["newline-removed"] = _19_, ["newline-added"] = _21_, ["blank-line-removed"] = _23_, ["spaces-collapsed"] = _25_, ["separation-removed"] = _27_, ["ast-same"] = _29_, ["ast-symbol"] = _31_, ["ast-comment"] = _33_, ["ast-second"] = _35_}
end
local function format_summary(source, config)
  local format = load_format()
  if format.error then
    return format
  else
    local ok, value, err
    local function _37_()
      return format["format-string"](source, {config = config})
    end
    ok, value, err = pcall(_37_)
    return {["value?"] = (ok and (nil ~= value)), ["has-message"] = (err and ("table" == type(err)) and ("string" == type(err.message))), message = (err and err.message), value = value}
  end
end
local function alignment_safety_scenario()
  local source = "(let [result {:code 0 \n:lines []}]\n  result)\n"
  local format = load_format()
  if format.error then
    return format
  else
    local ok, value, err
    local function _39_()
      return format["format-string"](source, {config = {["align-bindings"] = true}})
    end
    ok, value, err = pcall(_39_)
    return {["value?"] = (ok and (nil ~= value)), value = value, error = err}
  end
end
local function odd_binding_scenario()
  local source = "(let [a 1 b])"
  local format = load_format()
  if format.error then
    return format
  else
    local ok, value, err
    local function _41_()
      return format["format-string"](source, {config = {["align-bindings"] = true}})
    end
    ok, value, err = pcall(_41_)
    return {ok = ok, value = value, error = err}
  end
end
local function file_paths()
  local paths = {}
  local fnl_files = vim.fn.globpath("fnl", "**/*.fnl", false, true)
  local fnlm_files = vim.fn.globpath("fnl", "**/*.fnlm", false, true)
  for _, path in ipairs(fnl_files) do
    if not string.find(path, "^fnl/eca/nfnl/") then
      table.insert(paths, path)
    else
    end
  end
  for _, path in ipairs(fnlm_files) do
    if not string.find(path, "^fnl/eca/nfnl/") then
      table.insert(paths, path)
    else
    end
  end
  return paths
end
local function read_source(path)
  local ok, result
  local function _45_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_45_)
  if ok then
    return result
  else
    return {error = "read failed", path = path}
  end
end
local function format_file_scenario(format, parser, config, path, source, format_failures, idempotence_failures, indent_failures, ast_failures)
  local ok, formatted, err
  local function _47_()
    return format["format-string"](source, {config = config, parser = parser})
  end
  ok, formatted, err = pcall(_47_)
  if (not ok or (nil == formatted) or err) then
    return table.insert(format_failures, path)
  else
    local _
    local function _48_()
      return format["format-string"](formatted, {config = config, parser = parser})
    end
    if (not pcall(_48_) or (formatted ~= format["format-string"](formatted, {config = config, parser = parser}))) then
      _ = table.insert(idempotence_failures, path)
    else
      _ = nil
    end
    local _0
    if not format["indent-only?"](source, formatted) then
      _0 = table.insert(indent_failures, path)
    else
      _0 = nil
    end
    local _1
    if not format["ast-equal?"](parser, source, formatted) then
      _1 = table.insert(ast_failures, path)
    else
      _1 = nil
    end
    return nil
  end
end
local function repo_scenario()
  local format = load_format()
  local parser = load_parser()
  local config = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}, ["if"] = {{"block", 1}}}}
  local format_failures
  if format.error then
    format_failures = {"module missing"}
  else
    format_failures = {}
  end
  local idempotence_failures
  if format.error then
    idempotence_failures = {"module missing"}
  else
    idempotence_failures = {}
  end
  local indent_failures
  if format.error then
    indent_failures = {"module missing"}
  else
    indent_failures = {}
  end
  local ast_failures
  if format.error then
    ast_failures = {"module missing"}
  else
    ast_failures = {}
  end
  local fixed_point_failures = {}
  for _, path in ipairs(file_paths()) do
    local source = read_source(path)
    if source.error then
      for _0, failures in ipairs({format_failures, idempotence_failures, indent_failures, ast_failures}) do
        table.insert(failures, ("read failed: " .. path))
      end
    else
      format_file_scenario(format, parser, config, path, source, format_failures, idempotence_failures, indent_failures, ast_failures)
    end
  end
  for _, path in ipairs({"fnl/eca/ui/widgets/footer-bar.fnl", "fnl/eca/ui/components/lualine.fnl"}) do
    local source = read_source(path)
    if (source.error or format.error) then
      table.insert(fixed_point_failures, path)
    else
      local ok, formatted
      local function _58_()
        return format["format-string"](source, {config = config, parser = parser})
      end
      ok, formatted = pcall(_58_)
      if (not ok or (source ~= formatted)) then
        table.insert(fixed_point_failures, path)
      else
      end
    end
  end
  return {format = format_failures, idempotence = idempotence_failures, indent = indent_failures, ast = ast_failures, ["fixed-point"] = fixed_point_failures}
end
local function _61_()
  local function _62_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["indent-same"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"indent-same\")")
    return true
  end
  require("plenary.busted").it("indent-only accepts pure reindent", _62_)
  local function _63_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-string"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-string\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed string contents", _63_)
  local function _64_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-trailing"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-trailing\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed trailing whitespace", _64_)
  local function _65_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-lines"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-lines\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed line count", _65_)
  local function _66_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-char"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-char\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed non-whitespace characters", _66_)
  local function _67_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["binding-aligned"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"binding-aligned\")")
    return true
  end
  require("plenary.busted").it("binding whitespace accepts alignment between a name and value", _67_)
  local function _68_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["binding-joined"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"binding-joined\"))")
    return true
  end
  require("plenary.busted").it("binding whitespace rejects joined name and value tokens", _68_)
  local function _69_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["binding-string"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"binding-string\"))")
    return true
  end
  require("plenary.busted").it("binding whitespace rejects changed spaces inside string literals", _69_)
  local function _70_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["newline-removed"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"newline-removed\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects a removed newline", _70_)
  local function _71_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["newline-added"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"newline-added\")")
    return true
  end
  require("plenary.busted").it("indent-only accepts an added newline", _71_)
  local function _72_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["blank-line-removed"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"blank-line-removed\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects a removed blank line", _72_)
  local function _73_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["spaces-collapsed"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"spaces-collapsed\")")
    return true
  end
  require("plenary.busted").it("indent-only accepts collapsed spaces", _73_)
  local function _74_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["separation-removed"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"separation-removed\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects removed token separation", _74_)
  local function _75_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["ast-same"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"ast-same\")")
    return true
  end
  require("plenary.busted").it("ast-equal accepts differently indented equivalent forms", _75_)
  local function _76_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["ast-symbol"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"ast-symbol\"))")
    return true
  end
  require("plenary.busted").it("ast-equal rejects changed symbols", _76_)
  local function _77_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["ast-comment"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"ast-comment\"))")
    return true
  end
  require("plenary.busted").it("ast-equal rejects changed comment text", _77_)
  local function _78_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["ast-second"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"ast-second\"))")
    return true
  end
  return require("plenary.busted").it("ast-equal compares every top-level form", _78_)
end
require("plenary.busted").describe("verifier", _61_)
local function _79_()
  local function _80_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x\n  y)"
    local actual_7_auto = format_summary("(when x\ny)", {indents = {}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formats a simple conditional golden", _80_)
  local function _81_()
    local result = format_summary("(missing", {indents = {}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a structured error for unbalanced input", _81_)
  local function _82_()
    local result = format_summary("(x\ny)", {indents = {x = {{"inner", 1}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a structured error for an invalid config", _82_)
  local function _83_()
    local result = format_summary("(x\ny)", {["align-bindings"] = "yes"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a string align-bindings option", _83_)
  local function _84_()
    local result = format_summary("(x\ny)", {["align-bindings"] = 1})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric align-bindings option", _84_)
  local function _85_()
    local result = format_summary("(x\ny)", {["align-bindings"] = {}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a table align-bindings option", _85_)
  local function _86_()
    local result = format_summary("(x\ny)", {alignment = true})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, message = "alignment must be a table", ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"], message = result.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a boolean alignment value returns the documented validation error", _86_)
  local function _87_()
    local result = format_summary("(x\ny)", {alignment = "yes"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, message = "alignment must be a table", ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"], message = result.message}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a string alignment value returns the documented validation error", _87_)
  local function _88_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, value = "(let [result {:code  0 \n              :lines []}]\n  result)\n"}
    local actual_7_auto
    do
      local result = alignment_safety_scenario()
      actual_7_auto = {["value?"] = result["value?"], value = result.value}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("align-bindings formats a multiline map with trailing value whitespace", _88_)
end
require("plenary.busted").describe("format-string", _79_)
local function _89_()
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().format
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string succeeds for every project Fennel source", _90_)
  local function _91_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().idempotence
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string is idempotent for every project Fennel source", _91_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().indent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formatted output passes indent-only verification for every project source", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().ast
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formatted output preserves ASTs for every project source", _93_)
  local function _94_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario()["fixed-point"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("hand-styled files remain fixed points", _94_)
end
require("plenary.busted").describe("repo-properties", _89_)
local function _95_()
  local function _96_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n    x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {["indent-width"] = 4}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("indent width four changes block indentation", _96_)
  local function _97_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn [x]\n    x)"
    local actual_7_auto = format_summary("(fn [x]\nx)", {["indent-width"] = 4}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("indent width four changes inner indentation", _97_)
  local function _98_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n  x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the default indent width preserves today's output", _98_)
  local function _99_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n     x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {builtins = false}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("builtins false disables the let block rule", _99_)
  local function _100_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n     x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {builtins = {when = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom builtins table replaces the built-in table", _100_)
  local function _101_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x\n  y)"
    local actual_7_auto = format_summary("(when x\ny)", {builtins = {when = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom builtins table supplies its replacement rule", _101_)
  local function _102_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn x\n      y)"
    local actual_7_auto = format_summary("(defn x\ny)", {["prefix-fallbacks"] = false}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("prefix fallbacks false disables the def fallback", _102_)
  local function _103_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- git-root\n  [start]\n  (foo start))"
    local actual_7_auto = format_summary("(defn- git-root\n[start]\n(foo start))", {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("repo-style formatting indents defn args and body at two spaces", _103_)
  local function _104_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn x\n      y)"
    local actual_7_auto = format_summary("(defn x\ny)", {["prefix-fallbacks"] = {["with-"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom prefix fallback table replaces the defaults", _104_)
  local function _105_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo x\n  y)"
    local actual_7_auto = format_summary("(foo x\ny)", {["prefix-fallbacks"] = {["foo-"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom prefix fallback table supplies its replacement rule", _105_)
  local function _106_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x (print :a) (print :b) (let [y 1] y))"
    local actual_7_auto = format_summary("(when x (print :a) (print :b) (let [y 1] y))", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a long one-line form stays exactly one line", _106_)
  local function _107_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn [x] (fn [y] (+ x y)))"
    local actual_7_auto = format_summary("(fn [x] (fn [y] (+ x y)))", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested one-line fn stays exactly one line", _107_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 3
    local actual_7_auto
    do
      local value = format_summary("(when x\n(print :a)\n(print :b))", {}).value
      local _, count = string.gsub(value, "\n", "")
      actual_7_auto = (count + 1)
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("a multi-line form keeps its line count", _108_)
end
require("plenary.busted").describe("configuration-formatting", _95_)
local function _109_()
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {ok = true, value = "(let [a 1 b])", error = nil}
    local actual_7_auto
    do
      local result = odd_binding_scenario()
      actual_7_auto = {ok = result.ok, value = result.value, error = result.error}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("align-bindings leaves an odd-length binding vector unchanged without crashing", _110_)
end
require("plenary.busted").describe("odd-binding-vector", _109_)
local function format_summary_with_parser(source, config)
  local format = load_format()
  local parser = load_parser()
  if (format.error or parser.error) then
    return {value = nil, ["value?"] = false}
  else
    local ok, value, err
    local function _111_()
      return format["format-string"](source, {config = config, parser = parser})
    end
    ok, value, err = pcall(_111_)
    return {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("string" == type(err.message))), value = value}
  end
end
local function symbol_key_safety_scenario()
  local parser = load_parser()
  local format = load_format()
  local _113_
  if (parser.error or format.error) then
    _113_ = false
  else
    _113_ = format["ast-equal?"](parser, "{a 1}", "{a 1}")
  end
  local _115_
  if (parser.error or format.error) then
    _115_ = false
  else
    _115_ = format["ast-equal?"](parser, "{a 1}", "{a 2}")
  end
  local _117_
  if (parser.error or format.error) then
    _117_ = false
  else
    _117_ = format["ast-equal?"](parser, "{a 1}", "{b 1}")
  end
  return {same = _113_, ["different-value"] = _115_, ["different-key"] = _117_}
end
local function _119_()
  local function _120_()
    local result = format_summary_with_parser("{target true}", {})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, value = "{target true}"}
    local actual_7_auto = {["value?"] = result["value?"], value = result.value}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string preserves an unchanged symbol-keyed table", _120_)
  local function _121_()
    local result = format_summary_with_parser("(let [visited {target true}]\nvisited)", {})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, value = "(let [visited {target true}]\n  visited)"}
    local actual_7_auto = {["value?"] = result["value?"], value = result.value}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string reindents a let containing a symbol-keyed table", _121_)
  local function _122_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not symbol_key_safety_scenario()["different-value"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (symbol-key-safety-scenario) \"different-value\"))")
    return true
  end
  require("plenary.busted").it("ast-equal rejects a changed value with symbol keys", _122_)
  local function _123_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not symbol_key_safety_scenario()["different-key"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (symbol-key-safety-scenario) \"different-key\"))")
    return true
  end
  return require("plenary.busted").it("ast-equal rejects a changed key with symbol keys", _123_)
end
require("plenary.busted").describe("symbol-keyed-tables", _119_)
local function alignment_regression_scenario()
  local simple_source = "(defn f []\n(foo\nbar))"
  local if_source = "(if a\n    b\n    c)"
  local mixed_source = "(let [long-name 1\n x 2]\n(foo\nbar))"
  local value_source = "(let [a (foo\nbar)\n      long-name 2]\n baz)"
  local if_config = {indents = {["if"] = {{"block", 1}}}}
  local simple_off = format_summary(simple_source, {}).value
  local simple_on = format_summary(simple_source, {["align-bindings"] = true}).value
  local if_off = format_summary(if_source, if_config).value
  local if_on = format_summary(if_source, {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
  local mixed_off = format_summary(mixed_source, {}).value
  local mixed_on = format_summary(mixed_source, {["align-bindings"] = true}).value
  local value_off = format_summary(value_source, {}).value
  local value_on = format_summary(value_source, {["align-bindings"] = true}).value
  return {["simple-off"] = simple_off, ["simple-on"] = simple_on, ["if-off"] = if_off, ["if-on"] = if_on, ["mixed-off"] = mixed_off, ["mixed-on"] = mixed_on, ["value-off"] = value_off, ["value-on"] = value_on, ["mixed-idempotent"] = format_summary(mixed_on, {["align-bindings"] = true}).value, ["value-idempotent"] = format_summary(value_on, {["align-bindings"] = true}).value}
end
local function _124_()
  local function _125_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["simple-off"]
    local actual_7_auto = result["simple-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment preserves normal reindentation without binding vectors", _125_)
  local function _126_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if a\n  b\n  c)"
    local actual_7_auto = result["if-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment preserves custom if indentation", _126_)
  local function _127_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [long-name 1\n      x         2]\n  (foo\n   bar))"
    local actual_7_auto = result["mixed-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment applies binding alignment and unrelated reindentation", _127_)
  local function _128_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         (foo\n                 bar)\n      long-name 2]\n  baz)"
    local actual_7_auto = result["value-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts multiline value continuations with the moved value", _128_)
  local function _129_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["mixed-on"]
    local actual_7_auto = result["mixed-idempotent"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment output is idempotent for mixed reindentation", _129_)
  local function _130_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["value-on"]
    local actual_7_auto = result["value-idempotent"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("alignment output is idempotent for multiline moved values", _130_)
end
require("plenary.busted").describe("alignment-regressions", _124_)
local function stale_leading_whitespace_scenario()
  local if_source = "(defn f []\n  (if condition\n        (foo)\n        (bar)))"
  local top_if_source = "(if condition\n      (foo)\n      (bar))"
  local when_source = "(when condition\n          (foo))"
  local mixed_source = "(let [a 1\n      long-name 2]\n  (if condition\n        (foo)\n        (bar)))"
  local no_pairs_source = "(when condition\n          (foo)\n          (bar))"
  local if_config = {indents = {["if"] = {{"block", 1}}}}
  local if_on = format_summary(if_source, {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
  local top_if_on = format_summary(top_if_source, {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
  local when_on = format_summary(when_source, {["align-bindings"] = true}).value
  local mixed_config = {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}
  local mixed_on = format_summary(mixed_source, mixed_config).value
  local no_pairs_off = format_summary(no_pairs_source, {}).value
  local no_pairs_on = format_summary(no_pairs_source, {["align-bindings"] = true}).value
  return {["if-on"] = if_on, ["top-if-on"] = top_if_on, ["when-on"] = when_on, ["mixed-on"] = mixed_on, ["mixed-idempotent"] = format_summary(mixed_on, mixed_config).value, ["no-pairs-off"] = no_pairs_off, ["no-pairs-on"] = no_pairs_on}
end
local function nested_if_source(branch_spaces)
  return ("(defn outer []\n  (let [x 1]\n    (if condition\n" .. string.rep(" ", branch_spaces) .. "(foo)\n" .. string.rep(" ", branch_spaces) .. "(bar))))")
end
local function nested_if_expected()
  return "(defn outer []\n  (let [x 1]\n    (if condition\n      (foo)\n      (bar))))"
end
local function multiline_binding_source(name)
  return ("(let [a (foo\n         bar)\n      " .. name .. " 2]\n  a)")
end
local function _131_()
  local function _132_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn f []\n  (if condition\n    (foo)\n    (bar)))"
    local actual_7_auto = stale_leading_whitespace_scenario()["if-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment does not restore stale if branch indentation", _132_)
  local function _133_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if condition\n  (foo)\n  (bar))"
    local actual_7_auto = stale_leading_whitespace_scenario()["top-if-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment reindents top-level if branches", _133_)
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when condition\n  (foo))"
    local actual_7_auto = stale_leading_whitespace_scenario()["when-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment reindents over-indented when bodies", _134_)
  local function _135_()
    local result = stale_leading_whitespace_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         1\n      long-name 2]\n  (if condition\n    (foo)\n    (bar)))"
    local actual_7_auto = result["mixed-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment preserves binding alignment while reindenting if branches", _135_)
  local function _136_()
    local result = stale_leading_whitespace_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["mixed-on"]
    local actual_7_auto = result["mixed-idempotent"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment remains idempotent after correcting stale indentation", _136_)
  local function _137_()
    local result = stale_leading_whitespace_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["no-pairs-off"]
    local actual_7_auto = result["no-pairs-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("alignment matches normal formatting when no pairs are alignable", _137_)
end
require("plenary.busted").describe("stale-leading-whitespace", _131_)
local function leading_space_count(line)
  return #(string.match(line, "^( *)") or "")
end
local function balanced_line_3f(line)
  local open_text, opens = string.gsub(line, "[(]", "")
  local close_text, closes = string.gsub(line, "[)]", "")
  return (open_text and close_text and (opens == closes))
end
local function multiline_if_branch_violations(source)
  local lines = vim.split(source, "\n", true)
  local violations = {}
  for index, line in ipairs(lines) do
    local leading, rest = string.match(line, "^( *)%(if%s+(.+)$")
    if (leading and rest and balanced_line_3f(line) and ((index + 2) < (#lines + 1))) then
      local expected = (#leading + 2)
      local first = lines[(index + 1)]
      local second = lines[(index + 2)]
      if ((expected ~= leading_space_count(first)) or (expected ~= leading_space_count(second))) then
        table.insert(violations, {line = index, expected = expected, first = leading_space_count(first), second = leading_space_count(second)})
      else
      end
    else
    end
  end
  return violations
end
local function _140_()
  local function _141_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(7), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for one extra branch space", _141_)
  local function _142_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(8), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for two extra branch spaces", _142_)
  local function _143_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(9), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for three extra branch spaces", _143_)
  local function _144_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(10), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for four extra branch spaces", _144_)
  local function _145_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(11), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for five extra branch spaces", _145_)
  local function _146_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(5), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for one under-indented branch space", _146_)
  local function _147_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(4), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for two under-indented branch spaces", _147_)
  local function _148_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(3), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for three under-indented branch spaces", _148_)
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a (foo\n         bar)]\n  a)"
    local actual_7_auto = format_summary("(let [a (foo\n         bar)]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment does not move an unmoved multiline value continuation", _149_)
  local function _150_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a  (foo\n          bar)\n      bb 2]\n  a)"
    local actual_7_auto = format_summary(multiline_binding_source("bb"), {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts a multiline continuation by one column", _150_)
  local function _151_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a   (foo\n           bar)\n      bbb 2]\n  a)"
    local actual_7_auto = format_summary(multiline_binding_source("bbb"), {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts a multiline continuation by two columns", _151_)
  local function _152_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a    (foo\n            bar)\n      bbbb 2]\n  a)"
    local actual_7_auto = format_summary(multiline_binding_source("bbbb"), {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts a multiline continuation by three columns", _152_)
  local function _153_()
    local config = {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}, ["if"] = {{"block", 1}}}, ["align-bindings"] = true}
    local violations = {}
    for _, path in ipairs({"fnl/eca/api.fnl", "fnl/fennel-extras/lint.fnl"}) do
      local source = read_source(path)
      local result
      if source.error then
        result = source
      else
        result = format_summary(source, config)
      end
      if (source.error or not result["value?"]) then
        table.insert(violations, path)
      else
        for _0, violation in ipairs(multiline_if_branch_violations(result.value)) do
          table.insert(violations, (path .. ":" .. tostring(violation.line)))
        end
      end
    end
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = violations
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("repo if branches use the configured two-column indentation", _153_)
end
require("plenary.busted").describe("stale-leading-whitespace-remaining", _140_)
local function _156_()
  local function _157_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         1\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns let bindings to the longest single-line name", _157_)
  local function _158_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         #(+ $1 1)\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [a #(+ $1 1)\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a reader-prefix value", _158_)
  local function _159_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         '(foo bar)\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [a '(foo bar)\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a quoted value", _159_)
  local function _160_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [start#     1\n      long-name# 2]\n  start#)"
    local actual_7_auto = format_summary("(let [start# 1\n      long-name# 2]\n  start#)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns gensym names by their full text", _160_)
  local function _161_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a    1\n :long 2}"
    local actual_7_auto = format_summary("{:a 1\n :long 2}", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns map entries to the longest key", _161_)
  local function _162_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         1\n      b         2\n      long-name 3\n      c         4]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2\n      long-name 3\n      c 4]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits and aligns mixed binding lines", _162_)
  local function _163_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when-let [a         1\n           long-name 2]\n  a)"
    local actual_7_auto = format_summary("(when-let [a 1\n          long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns when-let bindings", _163_)
  local function _164_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if-let [a         1\n         long-name 2]\n  a\n  b)"
    local actual_7_auto = format_summary("(if-let [a 1\n        long-name 2]\n  a\n  b)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns if-let bindings", _164_)
  local function _165_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(with-open [a         1\n            long-name 2]\n  a)"
    local actual_7_auto = format_summary("(with-open [a 1\n          long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns with-open bindings", _165_)
  local function _166_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(each [k v\n       long-name 3]\n  k)"
    local actual_7_auto = format_summary("(each [k v\n      long-name 3]\n  k)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align loop bindings", _166_)
  local function _167_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "[1\n 2]"
    local actual_7_auto = format_summary("[1\n 2]", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align sequential tables", _167_)
  local function _168_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a  1\n      bb 1]\n  a)"
    local actual_7_auto = format_summary("(let [a     1\n      bb 1]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("normalizes extra spaces to the aligned column", _168_)
  local function _169_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         (foo\n                 bar)\n      long-name 2] a)"
    local actual_7_auto = format_summary("(let [a (foo\n         bar)\n      long-name 2] a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a multiline value and reindents its continuation", _169_)
  local function _170_()
    local source = "(let [a 1 b 2\n      long-name 3\n      c 4]\n  a)"
    local once = format_summary(source, {["align-bindings"] = true}).value
    local twice = format_summary(once, {["align-bindings"] = true}).value
    local assert_28_auto = require("luassert")
    local value_29_auto = (once and twice and (once == twice))
    assert_28_auto.is_truthy(value_29_auto, "(and once twice (= once twice))")
    return true
  end
  require("plenary.busted").it("formatting aligned mixed bindings is idempotent", _170_)
  local function _171_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [{: x}     (f)\n      long-name 2]\n  x)"
    local actual_7_auto = format_summary("(let [{: x} (f)\n      long-name 2]\n  x)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a destructuring map name by its full source width", _171_)
  local function _172_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [[a b]     (g)\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [[a b] (g)\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a destructuring vector name by its full source width", _172_)
  local function _173_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{(foo a)  1\n :long-key 2}"
    local actual_7_auto = format_summary("{(foo a) 1\n :long-key 2}", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns an expression map key by its full source width", _173_)
  local function _174_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [{: x\n       : y} (f)\n      a  1\n      bb 2] x)"
    local actual_7_auto = format_summary("(let [{: x\n       : y} (f)\n      a 1\n      bb 2] x)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores a multiline composite binding name while aligning single-line bindings", _174_)
  local function _175_()
    local source = "(let [a 1\n      long-name 2]\n  a)"
    local result = format_summary(source, {})
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = result.value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("align-bindings absent preserves the existing output byte-for-byte", _175_)
end
require("plenary.busted").describe("align-bindings", _156_)
local function _176_()
  local function _177_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x\n  \"--all\"     (a)\n  \"--changed\" (b)\n  _           (c))"
    local actual_7_auto = format_summary("(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns case clauses to the longest single-line pattern", _177_)
  local function _178_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(match value\n  :short (a)\n  :long  (b))"
    local actual_7_auto = format_summary("(match value\n  :short (a)\n  :long (b))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns match clauses to the longest single-line pattern", _178_)
  local function _179_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case-try (f)\n  x      (g x)\n  long-y (h y)\n  (catch _ nil))"
    local actual_7_auto = format_summary("(case-try (f)\n  x (g x)\n  long-y (h y)\n  (catch _ nil))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns case-try clauses but leaves catch unchanged", _179_)
  local function _180_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(match-try (f)\n  x      (g x)\n  long-y (h y)\n  (catch _ nil))"
    local actual_7_auto = format_summary("(match-try (f)\n  x (g x)\n  long-y (h y)\n  (catch _ nil))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns match-try clauses but leaves catch unchanged", _180_)
  local function _181_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if\n  (> i n)    false\n  (= path x) true\n  (rec))"
    local actual_7_auto = format_summary("(if\n  (> i n) false\n  (= path x) true\n  (rec))", {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns multi-clause if test and result children", _181_)
  local function _182_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if a\n  b\n  c)"
    local actual_7_auto = format_summary("(if a\n  b\n  c)", {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align a one-pair if with an else branch", _182_)
  local function _183_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x 1 :a\n  22 :b)"
    local actual_7_auto = format_summary("(case x 1 :a\n  22 :b)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align a clause pair sharing the case head line", _183_)
  local function _184_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(and\n a true\n long-name false)"
    local actual_7_auto = format_summary("(and\n  a true\n  long-name false)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align and clauses", _184_)
  local function _185_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x\n  (foo\n   a) :one\n  long-pattern :two ;; keep\n  short :three)"
    local actual_7_auto = format_summary("(case x\n  (foo\n   a) :one\n  long-pattern :two ;; keep\n  short :three)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align clause lines with comments or multiline patterns", _185_)
  local function _186_()
    local source = "(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))"
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = format_summary(source, {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings false preserves the case sample byte-for-byte", _186_)
  local function _187_()
    local source = "(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))\n(if\n  (> i n) false\n  (= path x) true\n  (rec))"
    local config = {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}
    local once = format_summary(source, config).value
    local twice = format_summary(once, config).value
    local assert_5_auto = require("luassert")
    local expected_6_auto = once
    local actual_7_auto = twice
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("clause alignment is idempotent on a mixed sample", _187_)
end
require("plenary.busted").describe("align-binding-clauses", _176_)
local function _188_()
  local function _189_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if\n  a b\n  c d\n  e)"
    local actual_7_auto = format_summary("(if\n a b\n  c d\n  e)", {indents = {["if"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("configured block-one if indents every own-line argument by two spaces", _189_)
  local function _190_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if\n  a\n  b)"
    local actual_7_auto = format_summary("(if\n   a\n   b)", {indents = {["if"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("configured block-one if indents a simple form by two spaces", _190_)
  local function _191_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when\n  a\n  b)"
    local actual_7_auto = format_summary("(when\n   a\n   b)", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("built-in when block indentation uses two spaces for every argument", _191_)
end
require("plenary.busted").describe("block-one-indentation", _188_)
local function comment_format_scenario(source, align_bindings)
  return format_summary(source, {indents = {deftest = {{"block", 1}}, testing = {{"block", 1}}, ["if"] = {{"block", 1}}}, ["align-bindings"] = align_bindings})
end
local function _192_()
  local function _193_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- rename-files\n  ;; comment\n  [temps]\n  (rename-loop temps 1 nil))"
    local actual_7_auto = comment_format_scenario("(defn- rename-files\n       ;; comment\n[temps]\n(rename-loop temps 1 nil))", false).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings false indents a defn header comment like the following code", _193_)
  local function _194_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn- rename-files\n  ;; comment\n  [temps]\n  (rename-loop temps 1 nil))"
    local actual_7_auto = comment_format_scenario("(defn- rename-files\n       ;; comment\n[temps]\n(rename-loop temps 1 nil))", true).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings true indents a defn header comment like the following code", _194_)
  local function _195_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn foo\n  [x]\n  ;; between\n  (bar)\n  (baz))"
    local actual_7_auto = comment_format_scenario("(defn foo\n[x]\n      ;; between\n(bar)\n(baz))", false).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings false indents a comment between defn body expressions", _195_)
  local function _196_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn foo\n  [x]\n  ;; between\n  (bar)\n  (baz))"
    local actual_7_auto = comment_format_scenario("(defn foo\n[x]\n      ;; between\n(bar)\n(baz))", true).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings true indents a comment between defn body expressions", _196_)
  local function _197_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n  ;; in let\n  x)"
    local actual_7_auto = comment_format_scenario("(let [x 1]\n     ;; in let\nx)", false).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings false indents a let comment like the following body", _197_)
  local function _198_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n  ;; in let\n  x)"
    local actual_7_auto = comment_format_scenario("(let [x 1]\n     ;; in let\nx)", true).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings true indents a let comment like the following body", _198_)
  local function _199_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [m {:a 1\n         ;; in map\n         :b 2}]\n  m)"
    local actual_7_auto = comment_format_scenario("(let [m {:a 1\n;; in map\n:b 2}]\nm)", false).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings false indents a map comment like the following key", _199_)
  local function _200_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [m {:a 1\n         ;; in map\n         :b 2}]\n  m)"
    local actual_7_auto = comment_format_scenario("(let [m {:a 1\n;; in map\n:b 2}]\nm)", true).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings true indents a map comment like the following key", _200_)
  local function _201_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = ";; first\n;; second\n(let [x 1]\n  x)"
    local actual_7_auto = comment_format_scenario(";; first\n;; second\n(let [x 1]\nx)", true).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a full-line comment block remains unchanged at top level", _201_)
  local function _202_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo ;; eol\n  bar)"
    local actual_7_auto = comment_format_scenario("(foo ;; eol\nbar)", true).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("an end-of-line comment stays attached while following code is indented", _202_)
end
require("plenary.busted").describe("comment-indentation", _192_)
local function _203_()
  local function _204_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a  1\n      bb 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 bb 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits a one-line let binding vector", _204_)
  local function _205_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a  1\n      bb 2]\n  a)"
    local actual_7_auto = format_summary("(let [a     1 bb    2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits and collapses padding in a one-line let binding vector", _205_)
  local function _206_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a 1 :bb 2}"
    local actual_7_auto = format_summary("{:a     1 :bb    2}", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("collapses padding in a one-line map", _206_)
  local function _207_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x 1 :a 2 :b)"
    local actual_7_auto = format_summary("(case x 1     :a 2     :b)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("collapses padding in one-line case clauses", _207_)
  local function _208_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a \"x  y\"}"
    local actual_7_auto = format_summary("{:a \"x  y\"}", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("leaves string contents unchanged", _208_)
  local function _209_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo a)   ;; c"
    local actual_7_auto = format_summary("(foo a)   ;; c", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("leaves end-of-line comments unchanged", _209_)
  local function _210_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a  1\n      bb 2]\n  a)"
    local actual_7_auto = format_summary("(let [a  1\n      bb 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("keeps multiline aligned forms aligned", _210_)
  local function _211_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a     1 bb    2]\n  a)"
    local actual_7_auto = format_summary("(let [a     1 bb    2]\n  a)", {["align-bindings"] = false}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("leaves padding unchanged when alignment is off", _211_)
  local function _212_()
    local first = format_summary("(let [a 1 bb 2]\n  a)", {["align-bindings"] = true}).value
    local second = format_summary(first, {["align-bindings"] = true}).value
    local assert_5_auto = require("luassert")
    local expected_6_auto = first
    local actual_7_auto = second
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment is idempotent", _212_)
  local function _213_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(local function-heads {:defn true :defn- true :fn true :lambda true :\206\187 true})"
    local actual_7_auto = format_summary("(local function-heads {:defn true :defn- true :fn true :lambda true :\206\187 true})", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves a one-line map with a multi-byte key already single-spaced", _213_)
  local function _214_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(local m {:a true :\206\187 true})"
    local actual_7_auto = format_summary("(local m {:a     true :\206\187  true})", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("collapses one-line map padding with a multi-byte key", _214_)
  local function _215_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [\206\187  1\n      bb 2]\n  \206\187)"
    local actual_7_auto = format_summary("(let [\206\187 1\n      bb 2]\n  \206\187)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a multi-byte let name by display width", _215_)
  local function _216_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a \"\206\187\206\187\"\n      b 2]\n  a)"
    local actual_7_auto = format_summary("(let [a     \"\206\187\206\187\" b 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("splits a one-line let with a multi-byte string value", _216_)
end
require("plenary.busted").describe("align-bindings-one-line-padding", _203_)
local function _217_()
  local function _218_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1\n      b 2\n      c 3]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2\n      c 3]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits a partially split let binding vector", _218_)
  local function _219_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo (let [a 1\n           b 2] a))"
    local actual_7_auto = format_summary("(foo (let [a 1 b 2] a))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits let bindings nested inside a call", _219_)
  local function _220_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when-let [a 1\n           b 2] a)"
    local actual_7_auto = format_summary("(when-let [a 1 b 2] a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits when-let bindings", _220_)
  local function _221_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if-let [a 1\n         b 2] a b)"
    local actual_7_auto = format_summary("(if-let [a 1 b 2] a b)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits if-let bindings", _221_)
  local function _222_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a (foo\n         1)\n      b 2]\n  a)"
    local actual_7_auto = format_summary("(let [a (foo\n         1) b 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits after a value spanning lines", _222_)
  local function _223_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [[x y] pt\n      z     3]\n  x)"
    local actual_7_auto = format_summary("(let [[x y] pt z 3]\n  x)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits a destructuring binding name", _223_)
  local function _224_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(each [k v (pairs t)]\n  (print k v))"
    local actual_7_auto = format_summary("(each [k v (pairs t)]\n  (print k v))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not split each binding vectors", _224_)
  local function _225_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1]\n  a)"
    local actual_7_auto = format_summary("(let [a 1]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not split single-pair let vectors", _225_)
  local function _226_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "'(let [a 1 b 2] a)"
    local actual_7_auto = format_summary("'(let [a 1 b 2] a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not split quoted let data", _226_)
  local function _227_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1 b 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2]\n  a)", {["align-bindings"] = false}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not split let vectors when alignment is off", _227_)
  local function _228_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1\n      b 2\n      c 3\n      d 4]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2 c 3 d 4]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits a four-pair let binding vector", _228_)
  local function _229_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1\n      b 2\n      c 3\n      d 4\n      e 5]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2\n      c 3 d 4\n      e 5]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("splits a partially split five-pair let binding vector", _229_)
  local function _230_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [;; note\n      a 1\n      b 2]\n  a)"
    local actual_7_auto = format_summary("(let [;; note\n      a 1 b 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("keeps a comment before split let bindings", _230_)
end
require("plenary.busted").describe("align-bindings-split", _217_)
local function _231_()
  local function _232_()
    local source = "(defn- parse-lint-args\n  [args]\n  (let [result {:a 1} state (lint-state args 2 result) (final-state error) (parse-lint-loop state)]\n    (parse-lint-result final-state error)))"
    local once = format_summary(source, {["align-bindings"] = true}).value
    local twice = format_summary(once, {["align-bindings"] = true}).value
    local expected = "(defn- parse-lint-args\n  [args]\n  (let [result              {:a 1}\n        state               (lint-state args 2 result)\n        (final-state error) (parse-lint-loop state)]\n    (parse-lint-result final-state error)))"
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected, once}
    local actual_7_auto = {once, twice}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("formats a nested multi-pair let idempotently", _232_)
end
require("plenary.busted").describe("align-bindings-idempotence", _231_)
local function _233_()
  local function _234_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a    1\n :long 2}"
    local actual_7_auto = format_summary("{:a 1\n :long 2}", {alignment = {maps = true}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("maps alignment aligns maps", _234_)
  local function _235_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1 b 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2]\n  a)", {alignment = {maps = true}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("maps alignment does not align let bindings or split one-line lets", _235_)
  local function _236_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1\n      b 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2]\n  a)", {alignment = {["split-bindings"] = true}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("split-bindings splits a let without aligning its names", _236_)
  local function _237_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         1\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1\n      long-name 2]\n  a)", {alignment = {bindings = true}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("bindings alignment aligns lets", _237_)
  local function _238_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a 1\n :long 2}"
    local actual_7_auto = format_summary("{:a 1\n :long 2}", {alignment = {bindings = true}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("bindings alignment does not align maps", _238_)
  local function _239_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x\n  \"--all\"     (a)\n  \"--changed\" (b)\n  _           (c))"
    local actual_7_auto = format_summary("(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))", {alignment = {clauses = true}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("clauses alignment aligns clause pairs", _239_)
  local function _240_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a 1 :bb 2}"
    local actual_7_auto = format_summary("{:a     1 :bb    2}", {alignment = {["collapse-padding"] = true, maps = true}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("collapse-padding collapses one-line map padding", _240_)
  local function _241_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when-let [a 1 b 2] a)"
    local actual_7_auto = format_summary("(when-let [a 1 b 2] a)", {alignment = {["split-bindings"] = true, ["binding-forms"] = {"let"}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("custom binding forms restrict splitting to the configured names", _241_)
  local function _242_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(my-let [a 1\n         b 2] a)"
    local actual_7_auto = format_summary("(my-let [a 1 b 2] a)", {alignment = {["split-bindings"] = true, ["binding-forms"] = {"my-let"}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("custom binding forms can add a form for splitting", _242_)
  local function _243_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(my-case x\n  short  (a)\n  longer (b))"
    local actual_7_auto = format_summary("(my-case x\n  short (a)\n  longer (b))", {alignment = {clauses = true, ["clause-forms"] = {"my-case"}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("custom clause forms enable alignment for the configured form", _243_)
  local function _244_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1 b 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2]\n  a)", {["align-bindings"] = true, alignment = {["split-bindings"] = false}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("explicit split-bindings false overrides align-bindings shorthand", _244_)
  local function _245_()
    local config = {alignment = {bindings = true, maps = true, clauses = true, ["split-bindings"] = true, ["collapse-padding"] = true}}
    local source = "(let [a 1 b 2]\n  a)\n{:a 1\n :long 2}"
    local once = format_summary(source, config).value
    local twice = format_summary(once, config).value
    local assert_5_auto = require("luassert")
    local expected_6_auto = once
    local actual_7_auto = twice
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("a configurable alignment combination is idempotent", _245_)
end
return require("plenary.busted").describe("configurable-alignment", _233_)
