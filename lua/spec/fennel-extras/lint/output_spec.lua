-- [nfnl] fnl/spec/fennel-extras/lint/output_spec.fnl
local function load_output()
  local ok, result = pcall(require, "fennel-extras.lint.output")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function text_lines(diagnostics)
  local output = load_output()
  if output["module-missing"] then
    return output
  else
    return output["text-lines"](diagnostics)
  end
end
local function json_lines(diagnostics)
  local output = load_output()
  if output["module-missing"] then
    return output
  else
    return output["json-lines"](diagnostics)
  end
end
local function sorted(diagnostics)
  local output = load_output()
  if output["module-missing"] then
    return output
  else
    return output.sort(diagnostics)
  end
end
local function diagnostic_signatures(diagnostics)
  local signatures = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(signatures, (diagnostic.path .. ":" .. diagnostic.line .. ":" .. diagnostic.rule .. ":" .. diagnostic.form .. ":" .. diagnostic.message))
  end
  return table.concat(signatures, "\n")
end
local function finding(overrides)
  local base = {kind = "finding", path = "fnl/app.fnl", line = 12, col = 5, ["end-line"] = 12, ["end-col"] = 18, severity = "error", rule = "forbidden-form", form = "fnl/app.fnl > module:app > defn:run > if#1 > then", message = "forbidden form"}
  for key, value in pairs(overrides) do
    base[key] = value
  end
  return base
end
local function json_case(message)
  return {message = message, json = json_lines({finding({message = message})})}
end
local function stale_exclusion(overrides)
  local base = {kind = "stale-exclusion", path = ".fnl-extras.fnl", line = 7, col = 9, severity = "error", rule = "forbidden-form", form = "fnl/app.fnl > module:app > defn:run > if#1 > then", message = "exclusion does not match any finding"}
  for key, value in pairs(overrides) do
    base[key] = value
  end
  return base
end
local function _5_()
  local function _6_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/app.fnl:12:5: error forbidden-form: forbidden form", "  exclusion: {:path \"fnl/app.fnl\"}"}
    local actual_7_auto = text_lines({finding({})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders an error finding and its valid copyable exclusion suggestion", _6_)
  local function _7_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/lib.fnl:3:2: warning module-import: use the target-style core binding", "  exclusion: {:path \"fnl/lib.fnl\"}"}
    local actual_7_auto = text_lines({finding({path = "fnl/lib.fnl", line = 3, col = 2, ["end-line"] = 3, ["end-col"] = 31, severity = "warning", rule = "module-import", form = "fnl/lib.fnl > top#1", message = "use the target-style core binding"})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders a warning finding with the same text contract", _7_)
  local function _8_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/app.fnl:12:5: error forbidden-form: forbidden form", "  description: explain this rule", "  exclusion: {:path \"fnl/app.fnl\"}"}
    local actual_7_auto = text_lines({finding({description = "explain this rule"})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders a separate description line only when configured", _8_)
  local function _9_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"fnl/quote.fnl:1:1: error custom: bad form", "  exclusion: {:path \"fnl/quote.fnl\"}"}
    local actual_7_auto = text_lines({finding({path = "fnl/quote.fnl", line = 1, col = 1, rule = "custom\"rule", form = "fnl/quote.fnl > top#1\\ > \"quoted\"", message = "bad form"})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("escapes a quote and backslash in the text exclusion snippet", _9_)
  local function _10_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {".fnl-extras.fnl:7:9: error forbidden-form: exclusion does not match any finding"}
    local actual_7_auto = text_lines({stale_exclusion({})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders a stale exclusion without a snippet", _10_)
  local function _11_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {".fnl-extras.fnl:7:9: error forbidden-form: exclusion does not match any finding"}
    local actual_7_auto = text_lines({stale_exclusion({description = "explain this rule"})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not render a description for a stale exclusion", _11_)
end
require("plenary.busted").describe("text-output", _5_)
local function _12_()
  local function _13_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"forbidden form\"}"}
    local actual_7_auto = json_lines({finding({})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("renders a finding as one exact ordered JSON object", _13_)
  local function _14_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"{\"kind\":\"stale-exclusion\",\"path\":\".fnl-extras.fnl\",\"line\":7,\"col\":9,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"exclusion does not match any finding\"}"}
    local actual_7_auto = json_lines({stale_exclusion({})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("omits end-line and end-col from stale exclusion JSON", _14_)
  local function _15_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {"{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"forbidden form\",\"description\":\"explain this rule\"}"}
    local actual_7_auto = json_lines({finding({description = "explain this rule"})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("includes an optional description only when configured", _15_)
  local function _16_()
    local slash = string.char(92)
    local control_path = ("p\"ath\\" .. "\n" .. "\t" .. "\r" .. string.char(1) .. string.char(31) .. "\195\169\240\159\152\128")
    local control_message = ("m\" \\ " .. "\n" .. "\t" .. "\r" .. string.char(1) .. " " .. string.char(31) .. " \195\169 \240\159\152\128")
    local expected = ("{\"kind\":\"finding\",\"path\":\"p" .. slash .. "\"" .. "ath" .. slash .. slash .. slash .. "n" .. slash .. "t" .. slash .. "r" .. slash .. "u0001" .. slash .. "u001F\195\169\240\159\152\128\",\"line\":1,\"col\":1,\"end-line\":1,\"end-col\":2,\"severity\":\"error\",\"rule\":\"r\",\"form\":\"f\",\"message\":\"m" .. slash .. "\"" .. " " .. slash .. slash .. " " .. slash .. "n" .. slash .. "t" .. slash .. "r" .. slash .. "u0001" .. " " .. slash .. "u001F \195\169 \240\159\152\128\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({path = control_path, line = 1, col = 1, ["end-line"] = 1, ["end-col"] = 2, rule = "r", form = "f", message = control_message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("escapes quote backslash newline tab carriage return controls and preserves UTF-8", _16_)
  local function _17_()
    local message = ("a" .. string.char(255) .. "b")
    local expected = ("{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"a" .. string.char(239) .. string.char(191) .. string.char(189) .. "b\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("replaces an invalid UTF-8 byte with U+FFFD in JSON", _17_)
  local function _18_()
    local message = string.char(195)
    local expected = ("{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" .. string.char(239) .. string.char(191) .. string.char(189) .. "\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("replaces a truncated UTF-8 sequence with U+FFFD in JSON", _18_)
  local function _19_()
    local message = string.char(127)
    local expected = ("{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" .. string.char(127) .. "\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves DEL as a raw byte in JSON", _19_)
  local function _20_()
    local message = "\195\169\240\159\152\128"
    local expected = "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"\195\169\240\159\152\128\"}"
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves valid UTF-8 in JSON", _20_)
  local function _21_()
    local message = (string.char(238) .. string.char(128) .. string.char(128))
    local expected = ("{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" .. message .. "\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves U+E000 bytes in JSON", _21_)
  local function _22_()
    local message = (string.char(239) .. string.char(191) .. string.char(189))
    local expected = ("{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" .. message .. "\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves U+FFFD bytes in JSON", _22_)
  local function _23_()
    local message = (string.char(239) .. string.char(191) .. string.char(191))
    local expected = ("{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\"" .. message .. "\"}")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {expected}
    local actual_7_auto = json_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves U+FFFF bytes in JSON", _23_)
  local function _24_()
    local replacement = (string.char(239) .. string.char(191) .. string.char(189))
    local prefix = "{\"kind\":\"finding\",\"path\":\"fnl/app.fnl\",\"line\":12,\"col\":5,\"end-line\":12,\"end-col\":18,\"severity\":\"error\",\"rule\":\"forbidden-form\",\"form\":\"fnl/app.fnl > module:app > defn:run > if#1 > then\",\"message\":\""
    local suffix = "\"}"
    local cases = {u007f = string.char(127), u0080 = (string.char(194) .. string.char(128)), u07ff = (string.char(223) .. string.char(191)), u0800 = (string.char(224) .. string.char(160) .. string.char(128)), uD7FF = (string.char(237) .. string.char(159) .. string.char(191)), u10000 = (string.char(240) .. string.char(144) .. string.char(128) .. string.char(128)), u10FFFF = (string.char(244) .. string.char(143) .. string.char(191) .. string.char(191)), surrogate = (string.char(237) .. string.char(160) .. string.char(128)), ["above-u10FFFF"] = (string.char(244) .. string.char(144) .. string.char(128) .. string.char(128)), ["overlong-two"] = (string.char(192) .. string.char(128)), ["overlong-three"] = (string.char(224) .. string.char(128) .. string.char(128))}
    local actual = {}
    local expected = {u007f = {message = cases.u007f, json = {(prefix .. cases.u007f .. suffix)}}, u0080 = {message = cases.u0080, json = {(prefix .. cases.u0080 .. suffix)}}, u07ff = {message = cases.u07ff, json = {(prefix .. cases.u07ff .. suffix)}}, u0800 = {message = cases.u0800, json = {(prefix .. cases.u0800 .. suffix)}}, uD7FF = {message = cases.uD7FF, json = {(prefix .. cases.uD7FF .. suffix)}}, u10000 = {message = cases.u10000, json = {(prefix .. cases.u10000 .. suffix)}}, u10FFFF = {message = cases.u10FFFF, json = {(prefix .. cases.u10FFFF .. suffix)}}, surrogate = {message = cases.surrogate, json = {(prefix .. replacement .. replacement .. replacement .. suffix)}}, ["above-u10FFFF"] = {message = cases["above-u10FFFF"], json = {(prefix .. replacement .. replacement .. replacement .. replacement .. suffix)}}, ["overlong-two"] = {message = cases["overlong-two"], json = {(prefix .. replacement .. replacement .. suffix)}}, ["overlong-three"] = {message = cases["overlong-three"], json = {(prefix .. replacement .. replacement .. replacement .. suffix)}}}
    for key, message in pairs(cases) do
      actual[key] = json_case(message)
    end
    local assert_5_auto = require("luassert")
    local expected_6_auto = expected
    local actual_7_auto = actual
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("handles UTF-8 boundary bytes and invalid sequences in JSON", _24_)
  local function _25_()
    local message = ("a" .. string.char(255) .. "b")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {("fnl/app.fnl:12:5: error forbidden-form: " .. message), "  exclusion: {:path \"fnl/app.fnl\"}"}
    local actual_7_auto = text_lines({finding({message = message})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("preserves invalid UTF-8 bytes in text output", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = #json_lines({finding({}), stale_exclusion({})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns one JSON object per diagnostic without embedded newlines", _26_)
end
require("plenary.busted").describe("json-output", _12_)
local function _27_()
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {finding({path = "a.fnl", line = 1, col = 1, severity = "error", rule = "a", form = "a", message = "z"}), finding({path = "a.fnl", line = 1, col = 1, severity = "warning", rule = "a", form = "a", message = "a"}), finding({path = "b.fnl", line = 1, col = 1, severity = "error", rule = "a", form = "a", message = "a"})}
    local actual_7_auto = sorted({finding({path = "b.fnl", line = 1, col = 1, severity = "error", rule = "a", form = "a", message = "a"}), finding({path = "a.fnl", line = 1, col = 1, severity = "warning", rule = "a", form = "a", message = "a"}), finding({path = "a.fnl", line = 1, col = 1, severity = "error", rule = "a", form = "a", message = "z"})})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("sorts by path line column severity rule form and message", _28_)
  local function _29_()
    local input = {finding({path = "b.fnl"}), finding({path = "a.fnl"})}
    local before = diagnostic_signatures(input)
    local first = sorted(input)
    local second = sorted(input)
    local assert_28_auto = require("luassert")
    local value_29_auto = ((before == diagnostic_signatures(input)) and (diagnostic_signatures(first) == diagnostic_signatures(second)) and not (input == first))
    assert_28_auto.is_truthy(value_29_auto, "(and (= before (diagnostic-signatures input)) (= (diagnostic-signatures first) (diagnostic-signatures second)) (not (= input first)))")
    return true
  end
  require("plenary.busted").it("does not mutate its input and is deterministic across repeated calls", _29_)
  local function _30_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {}
    local actual_7_auto = sorted({})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns an empty list for empty input", _30_)
end
return require("plenary.busted").describe("ordering-and-purity", _27_)
