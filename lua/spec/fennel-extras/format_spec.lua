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
  if (format.error or parser.error) then
    _19_ = false
  else
    _19_ = format["ast-equal?"](parser, same_a, same_b)
  end
  local _21_
  if (format.error or parser.error) then
    _21_ = true
  else
    _21_ = format["ast-equal?"](parser, symbol_a, symbol_b)
  end
  local _23_
  if (format.error or parser.error) then
    _23_ = true
  else
    _23_ = format["ast-equal?"](parser, comment_a, comment_b)
  end
  local _25_
  if (format.error or parser.error) then
    _25_ = true
  else
    _25_ = format["ast-equal?"](parser, second_a, second_b)
  end
  return {["indent-same"] = _3_, ["indent-string"] = _5_, ["indent-trailing"] = _7_, ["indent-lines"] = _9_, ["indent-char"] = _11_, ["binding-aligned"] = _13_, ["binding-joined"] = _15_, ["binding-string"] = _17_, ["ast-same"] = _19_, ["ast-symbol"] = _21_, ["ast-comment"] = _23_, ["ast-second"] = _25_}
end
local function format_summary(source, config)
  local format = load_format()
  if format.error then
    return format
  else
    local ok, value, err
    local function _27_()
      return format["format-string"](source, {config = config})
    end
    ok, value, err = pcall(_27_)
    return {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("string" == type(err.message))), value = value}
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
  local function _31_()
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
  end
  ok, result = pcall(_31_)
  if ok then
    return result
  else
    return {error = "read failed", path = path}
  end
end
local function format_file_scenario(format, parser, config, path, source, format_failures, idempotence_failures, indent_failures, ast_failures)
  local ok, formatted, err
  local function _33_()
    return format["format-string"](source, {config = config, parser = parser})
  end
  ok, formatted, err = pcall(_33_)
  if (not ok or (nil == formatted) or err) then
    return table.insert(format_failures, path)
  else
    local _
    local function _34_()
      return format["format-string"](formatted, {config = config, parser = parser})
    end
    if (not pcall(_34_) or (formatted ~= format["format-string"](formatted, {config = config, parser = parser}))) then
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
      local function _44_()
        return format["format-string"](source, {config = config, parser = parser})
      end
      ok, formatted = pcall(_44_)
      if (not ok or (source ~= formatted)) then
        table.insert(fixed_point_failures, path)
      else
      end
    end
  end
  return {format = format_failures, idempotence = idempotence_failures, indent = indent_failures, ast = ast_failures, ["fixed-point"] = fixed_point_failures}
end
local function _47_()
  local function _48_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["indent-same"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"indent-same\")")
    return true
  end
  require("plenary.busted").it("indent-only accepts pure reindent", _48_)
  local function _49_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-string"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-string\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed string contents", _49_)
  local function _50_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-trailing"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-trailing\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed trailing whitespace", _50_)
  local function _51_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-lines"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-lines\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed line count", _51_)
  local function _52_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["indent-char"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"indent-char\"))")
    return true
  end
  require("plenary.busted").it("indent-only rejects changed non-whitespace characters", _52_)
  local function _53_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["binding-aligned"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"binding-aligned\")")
    return true
  end
  require("plenary.busted").it("binding whitespace accepts alignment between a name and value", _53_)
  local function _54_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["binding-joined"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"binding-joined\"))")
    return true
  end
  require("plenary.busted").it("binding whitespace rejects joined name and value tokens", _54_)
  local function _55_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["binding-string"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"binding-string\"))")
    return true
  end
  require("plenary.busted").it("binding whitespace rejects changed spaces inside string literals", _55_)
  local function _56_()
    local assert_28_auto = require("luassert")
    local value_29_auto = verifier_scenario()["ast-same"]
    assert_28_auto.is_truthy(value_29_auto, "(. (verifier-scenario) \"ast-same\")")
    return true
  end
  require("plenary.busted").it("ast-equal accepts differently indented equivalent forms", _56_)
  local function _57_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["ast-symbol"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"ast-symbol\"))")
    return true
  end
  require("plenary.busted").it("ast-equal rejects changed symbols", _57_)
  local function _58_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["ast-comment"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"ast-comment\"))")
    return true
  end
  require("plenary.busted").it("ast-equal rejects changed comment text", _58_)
  local function _59_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not verifier_scenario()["ast-second"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (verifier-scenario) \"ast-second\"))")
    return true
  end
  return require("plenary.busted").it("ast-equal compares every top-level form", _59_)
end
require("plenary.busted").describe("verifier", _47_)
local function _60_()
  local function _61_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x\n  y)"
    local actual_7_auto = format_summary("(when x\ny)", {indents = {}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formats a simple conditional golden", _61_)
  local function _62_()
    local result = format_summary("(missing", {indents = {}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a structured error for unbalanced input", _62_)
  local function _63_()
    local result = format_summary("(x\ny)", {indents = {x = {{"inner", 1}}}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns a structured error for an invalid config", _63_)
  local function _64_()
    local result = format_summary("(x\ny)", {["align-bindings"] = "yes"})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a string align-bindings option", _64_)
  local function _65_()
    local result = format_summary("(x\ny)", {["align-bindings"] = 1})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a numeric align-bindings option", _65_)
  local function _66_()
    local result = format_summary("(x\ny)", {["align-bindings"] = {}})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["has-message"] = true, ["value?"] = false}
    local actual_7_auto = {["value?"] = result["value?"], ["has-message"] = result["has-message"]}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("rejects a table align-bindings option", _66_)
end
require("plenary.busted").describe("format-string", _60_)
local function _67_()
  local function _68_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().format
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string succeeds for every project Fennel source", _68_)
  local function _69_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().idempotence
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string is idempotent for every project Fennel source", _69_)
  local function _70_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().indent
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formatted output passes indent-only verification for every project source", _70_)
  local function _71_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario().ast
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formatted output preserves ASTs for every project source", _71_)
  local function _72_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = repo_scenario()["fixed-point"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("hand-styled files remain fixed points", _72_)
end
require("plenary.busted").describe("repo-properties", _67_)
local function _73_()
  local function _74_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n    x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {["indent-width"] = 4}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("indent width four changes block indentation", _74_)
  local function _75_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn [x]\n    x)"
    local actual_7_auto = format_summary("(fn [x]\nx)", {["indent-width"] = 4}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("indent width four changes inner indentation", _75_)
  local function _76_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n  x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("the default indent width preserves today's output", _76_)
  local function _77_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n     x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {builtins = false}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("builtins false disables the let block rule", _77_)
  local function _78_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [x 1]\n     x)"
    local actual_7_auto = format_summary("(let [x 1]\nx)", {builtins = {when = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom builtins table replaces the built-in table", _78_)
  local function _79_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x\n  y)"
    local actual_7_auto = format_summary("(when x\ny)", {builtins = {when = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom builtins table supplies its replacement rule", _79_)
  local function _80_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn x\n      y)"
    local actual_7_auto = format_summary("(defn x\ny)", {["prefix-fallbacks"] = false}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("prefix fallbacks false disables the def fallback", _80_)
  local function _81_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn x\n      y)"
    local actual_7_auto = format_summary("(defn x\ny)", {["prefix-fallbacks"] = {["with-"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom prefix fallback table replaces the defaults", _81_)
  local function _82_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(foo x\n  y)"
    local actual_7_auto = format_summary("(foo x\ny)", {["prefix-fallbacks"] = {["foo-"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a custom prefix fallback table supplies its replacement rule", _82_)
  local function _83_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when x (print :a) (print :b) (let [y 1] y))"
    local actual_7_auto = format_summary("(when x (print :a) (print :b) (let [y 1] y))", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a long one-line form stays exactly one line", _83_)
  local function _84_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(fn [x] (fn [y] (+ x y)))"
    local actual_7_auto = format_summary("(fn [x] (fn [y] (+ x y)))", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a nested one-line fn stays exactly one line", _84_)
  local function _85_()
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
  return require("plenary.busted").it("a multi-line form keeps its line count", _85_)
end
require("plenary.busted").describe("configuration-formatting", _73_)
local function format_summary_with_parser(source, config)
  local format = load_format()
  local parser = load_parser()
  if (format.error or parser.error) then
    return {value = nil, ["value?"] = false}
  else
    local ok, value, err
    local function _86_()
      return format["format-string"](source, {config = config, parser = parser})
    end
    ok, value, err = pcall(_86_)
    return {["value?"] = (ok and (nil ~= value)), ["has-message"] = (ok and (nil == value) and err and ("string" == type(err.message))), value = value}
  end
end
local function symbol_key_safety_scenario()
  local parser = load_parser()
  local format = load_format()
  local _88_
  if (parser.error or format.error) then
    _88_ = false
  else
    _88_ = format["ast-equal?"](parser, "{a 1}", "{a 1}")
  end
  local _90_
  if (parser.error or format.error) then
    _90_ = false
  else
    _90_ = format["ast-equal?"](parser, "{a 1}", "{a 2}")
  end
  local _92_
  if (parser.error or format.error) then
    _92_ = false
  else
    _92_ = format["ast-equal?"](parser, "{a 1}", "{b 1}")
  end
  return {same = _88_, ["different-value"] = _90_, ["different-key"] = _92_}
end
local function _94_()
  local function _95_()
    local result = format_summary_with_parser("{target true}", {})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, value = "{target true}"}
    local actual_7_auto = {["value?"] = result["value?"], value = result.value}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string preserves an unchanged symbol-keyed table", _95_)
  local function _96_()
    local result = format_summary_with_parser("(let [visited {target true}]\nvisited)", {})
    local assert_5_auto = require("luassert")
    local expected_6_auto = {["value?"] = true, value = "(let [visited {target true}]\n  visited)"}
    local actual_7_auto = {["value?"] = result["value?"], value = result.value}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("format-string reindents a let containing a symbol-keyed table", _96_)
  local function _97_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not symbol_key_safety_scenario()["different-value"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (symbol-key-safety-scenario) \"different-value\"))")
    return true
  end
  require("plenary.busted").it("ast-equal rejects a changed value with symbol keys", _97_)
  local function _98_()
    local assert_28_auto = require("luassert")
    local value_29_auto = not symbol_key_safety_scenario()["different-key"]
    assert_28_auto.is_truthy(value_29_auto, "(not (. (symbol-key-safety-scenario) \"different-key\"))")
    return true
  end
  return require("plenary.busted").it("ast-equal rejects a changed key with symbol keys", _98_)
end
require("plenary.busted").describe("symbol-keyed-tables", _94_)
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
local function _99_()
  local function _100_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["simple-off"]
    local actual_7_auto = result["simple-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment preserves normal reindentation without binding vectors", _100_)
  local function _101_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if a\n  b\n  c)"
    local actual_7_auto = result["if-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment preserves custom if indentation", _101_)
  local function _102_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [long-name 1\n      x         2]\n  (foo\n   bar))"
    local actual_7_auto = result["mixed-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment applies binding alignment and unrelated reindentation", _102_)
  local function _103_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         (foo\n                 bar)\n      long-name 2]\n  baz)"
    local actual_7_auto = result["value-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts multiline value continuations with the moved value", _103_)
  local function _104_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["mixed-on"]
    local actual_7_auto = result["mixed-idempotent"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment output is idempotent for mixed reindentation", _104_)
  local function _105_()
    local result = alignment_regression_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["value-on"]
    local actual_7_auto = result["value-idempotent"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("alignment output is idempotent for multiline moved values", _105_)
end
require("plenary.busted").describe("alignment-regressions", _99_)
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
local function _106_()
  local function _107_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(defn f []\n  (if condition\n    (foo)\n    (bar)))"
    local actual_7_auto = stale_leading_whitespace_scenario()["if-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment does not restore stale if branch indentation", _107_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if condition\n  (foo)\n  (bar))"
    local actual_7_auto = stale_leading_whitespace_scenario()["top-if-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment reindents top-level if branches", _108_)
  local function _109_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when condition\n  (foo))"
    local actual_7_auto = stale_leading_whitespace_scenario()["when-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment reindents over-indented when bodies", _109_)
  local function _110_()
    local result = stale_leading_whitespace_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         1\n      long-name 2]\n  (if condition\n    (foo)\n    (bar)))"
    local actual_7_auto = result["mixed-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment preserves binding alignment while reindenting if branches", _110_)
  local function _111_()
    local result = stale_leading_whitespace_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["mixed-on"]
    local actual_7_auto = result["mixed-idempotent"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment remains idempotent after correcting stale indentation", _111_)
  local function _112_()
    local result = stale_leading_whitespace_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = result["no-pairs-off"]
    local actual_7_auto = result["no-pairs-on"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("alignment matches normal formatting when no pairs are alignable", _112_)
end
require("plenary.busted").describe("stale-leading-whitespace", _106_)
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
local function _115_()
  local function _116_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(7), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for one extra branch space", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(8), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for two extra branch spaces", _117_)
  local function _118_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(9), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for three extra branch spaces", _118_)
  local function _119_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(10), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for four extra branch spaces", _119_)
  local function _120_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(11), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for five extra branch spaces", _120_)
  local function _121_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(5), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for one under-indented branch space", _121_)
  local function _122_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(4), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for two under-indented branch spaces", _122_)
  local function _123_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = nested_if_expected()
    local actual_7_auto = format_summary(nested_if_source(3), {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment uses normal indentation for three under-indented branch spaces", _123_)
  local function _124_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a (foo\n         bar)]\n  a)"
    local actual_7_auto = format_summary("(let [a (foo\n         bar)]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment does not move an unmoved multiline value continuation", _124_)
  local function _125_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a  (foo\n          bar)\n      bb 2]\n  a)"
    local actual_7_auto = format_summary(multiline_binding_source("bb"), {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts a multiline continuation by one column", _125_)
  local function _126_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a   (foo\n           bar)\n      bbb 2]\n  a)"
    local actual_7_auto = format_summary(multiline_binding_source("bbb"), {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts a multiline continuation by two columns", _126_)
  local function _127_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a    (foo\n            bar)\n      bbbb 2]\n  a)"
    local actual_7_auto = format_summary(multiline_binding_source("bbbb"), {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("alignment shifts a multiline continuation by three columns", _127_)
  local function _128_()
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
  return require("plenary.busted").it("repo if branches use the configured two-column indentation", _128_)
end
require("plenary.busted").describe("stale-leading-whitespace-remaining", _115_)
local function _131_()
  local function _132_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         1\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [a 1\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns let bindings to the longest single-line name", _132_)
  local function _133_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         #(+ $1 1)\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [a #(+ $1 1)\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a reader-prefix value", _133_)
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         '(foo bar)\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [a '(foo bar)\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a quoted value", _134_)
  local function _135_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [start#     1\n      long-name# 2]\n  start#)"
    local actual_7_auto = format_summary("(let [start# 1\n      long-name# 2]\n  start#)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns gensym names by their full text", _135_)
  local function _136_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{:a    1\n :long 2}"
    local actual_7_auto = format_summary("{:a 1\n :long 2}", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns map entries to the longest key", _136_)
  local function _137_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a 1 b 2\n      long-name 3\n      c         4]\n  a)"
    local actual_7_auto = format_summary("(let [a 1 b 2\n      long-name 3\n      c 4]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns only single-pair lines in a mixed binding line", _137_)
  local function _138_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when-let [a         1\n           long-name 2]\n  a)"
    local actual_7_auto = format_summary("(when-let [a 1\n          long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns when-let bindings", _138_)
  local function _139_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if-let [a         1\n         long-name 2]\n  a\n  b)"
    local actual_7_auto = format_summary("(if-let [a 1\n        long-name 2]\n  a\n  b)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns if-let bindings", _139_)
  local function _140_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(with-open [a         1\n            long-name 2]\n  a)"
    local actual_7_auto = format_summary("(with-open [a 1\n          long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns with-open bindings", _140_)
  local function _141_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(each [k v\n       long-name 3]\n  k)"
    local actual_7_auto = format_summary("(each [k v\n      long-name 3]\n  k)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align loop bindings", _141_)
  local function _142_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "[1\n 2]"
    local actual_7_auto = format_summary("[1\n 2]", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align sequential tables", _142_)
  local function _143_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a  1\n      bb 1]\n  a)"
    local actual_7_auto = format_summary("(let [a     1\n      bb 1]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("normalizes extra spaces to the aligned column", _143_)
  local function _144_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [a         (foo\n                 bar)\n      long-name 2] a)"
    local actual_7_auto = format_summary("(let [a (foo\n         bar)\n      long-name 2] a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a multiline value and reindents its continuation", _144_)
  local function _145_()
    local source = "(let [a 1 b 2\n      long-name 3\n      c 4]\n  a)"
    local once = format_summary(source, {["align-bindings"] = true}).value
    local twice = format_summary(once, {["align-bindings"] = true}).value
    local assert_28_auto = require("luassert")
    local value_29_auto = (once and twice and (once == twice))
    assert_28_auto.is_truthy(value_29_auto, "(and once twice (= once twice))")
    return true
  end
  require("plenary.busted").it("formatting aligned mixed bindings is idempotent", _145_)
  local function _146_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [{: x}     (f)\n      long-name 2]\n  x)"
    local actual_7_auto = format_summary("(let [{: x} (f)\n      long-name 2]\n  x)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a destructuring map name by its full source width", _146_)
  local function _147_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [[a b]     (g)\n      long-name 2]\n  a)"
    local actual_7_auto = format_summary("(let [[a b] (g)\n      long-name 2]\n  a)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns a destructuring vector name by its full source width", _147_)
  local function _148_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "{(foo a)  1\n :long-key 2}"
    local actual_7_auto = format_summary("{(foo a) 1\n :long-key 2}", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns an expression map key by its full source width", _148_)
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(let [{: x\n       : y} (f)\n      a  1\n      bb 2] x)"
    local actual_7_auto = format_summary("(let [{: x\n       : y} (f)\n      a 1\n      bb 2] x)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("ignores a multiline composite binding name while aligning single-line bindings", _149_)
  local function _150_()
    local source = "(let [a 1\n      long-name 2]\n  a)"
    local result = format_summary(source, {})
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = result.value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("align-bindings absent preserves the existing output byte-for-byte", _150_)
end
require("plenary.busted").describe("align-bindings", _131_)
local function _151_()
  local function _152_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x\n  \"--all\"     (a)\n  \"--changed\" (b)\n  _           (c))"
    local actual_7_auto = format_summary("(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns case clauses to the longest single-line pattern", _152_)
  local function _153_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(match value\n  :short (a)\n  :long  (b))"
    local actual_7_auto = format_summary("(match value\n  :short (a)\n  :long (b))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns match clauses to the longest single-line pattern", _153_)
  local function _154_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case-try (f)\n  x      (g x)\n  long-y (h y)\n  (catch _ nil))"
    local actual_7_auto = format_summary("(case-try (f)\n  x (g x)\n  long-y (h y)\n  (catch _ nil))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns case-try clauses but leaves catch unchanged", _154_)
  local function _155_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(match-try (f)\n  x      (g x)\n  long-y (h y)\n  (catch _ nil))"
    local actual_7_auto = format_summary("(match-try (f)\n  x (g x)\n  long-y (h y)\n  (catch _ nil))", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns match-try clauses but leaves catch unchanged", _155_)
  local function _156_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if\n  (> i n)    false\n  (= path x) true\n  (rec))"
    local actual_7_auto = format_summary("(if\n  (> i n) false\n  (= path x) true\n  (rec))", {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("aligns multi-clause if test and result children", _156_)
  local function _157_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if a\n  b\n  c)"
    local actual_7_auto = format_summary("(if a\n  b\n  c)", {indents = {["if"] = {{"block", 1}}}, ["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align a one-pair if with an else branch", _157_)
  local function _158_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x 1 :a\n  22 :b)"
    local actual_7_auto = format_summary("(case x 1 :a\n  22 :b)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align a clause pair sharing the case head line", _158_)
  local function _159_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(and\n a true\n long-name false)"
    local actual_7_auto = format_summary("(and\n  a true\n  long-name false)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align and clauses", _159_)
  local function _160_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(case x\n  (foo\n   a) :one\n  long-pattern :two ;; keep\n  short :three)"
    local actual_7_auto = format_summary("(case x\n  (foo\n   a) :one\n  long-pattern :two ;; keep\n  short :three)", {["align-bindings"] = true}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not align clause lines with comments or multiline patterns", _160_)
  local function _161_()
    local source = "(case x\n  \"--all\" (a)\n  \"--changed\" (b)\n  _ (c))"
    local assert_5_auto = require("luassert")
    local expected_6_auto = source
    local actual_7_auto = format_summary(source, {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("align-bindings false preserves the case sample byte-for-byte", _161_)
  local function _162_()
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
  return require("plenary.busted").it("clause alignment is idempotent on a mixed sample", _162_)
end
require("plenary.busted").describe("align-binding-clauses", _151_)
local function _163_()
  local function _164_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if\n  a b\n  c d\n  e)"
    local actual_7_auto = format_summary("(if\n a b\n  c d\n  e)", {indents = {["if"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("configured block-one if indents every own-line argument by two spaces", _164_)
  local function _165_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(if\n  a\n  b)"
    local actual_7_auto = format_summary("(if\n   a\n   b)", {indents = {["if"] = {{"block", 1}}}}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("configured block-one if indents a simple form by two spaces", _165_)
  local function _166_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = "(when\n  a\n  b)"
    local actual_7_auto = format_summary("(when\n   a\n   b)", {}).value
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("built-in when block indentation uses two spaces for every argument", _166_)
end
return require("plenary.busted").describe("block-one-indentation", _163_)
