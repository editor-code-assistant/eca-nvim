-- [nfnl] fnl/spec/fennel-extras/cli_spec.fnl
local function load_cli()
  local ok, result = pcall(require, "fennel-extras.cli")
  if ok then
    return result
  else
    return {["module-missing"] = true}
  end
end
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function write_file(path, text)
  local file = assert(io.open(path, "w"))
  file:write(text)
  file:close()
  return path
end
local function read_file(path)
  local file = assert(io.open(path, "r"))
  local text = file:read("*a")
  file:close()
  return text
end
local function format_config(body)
  local workspace_3f = (string.find(body, ":paths") or string.find(body, ":exclude") or string.find(body, ":extensions") or string.find(body, ":dotfiles") or string.find(body, ":symlinks") or string.find(body, ":config"))
  local workspace
  if workspace_3f then
    local _3_
    if string.find(body, ":extensions") then
      _3_ = ""
    else
      _3_ = " :extensions [\".fnl\" \".fnlm\"]"
    end
    local _5_
    if string.find(body, ":dotfiles") then
      _5_ = ""
    else
      _5_ = " :dotfiles false"
    end
    local _7_
    if string.find(body, ":symlinks") then
      _7_ = ""
    else
      _7_ = " :symlinks false"
    end
    local _9_
    if string.find(body, ":paths") then
      _9_ = ""
    else
      _9_ = " :paths [\".\"]"
    end
    workspace = ("{" .. body .. _3_ .. _5_ .. _7_ .. _9_ .. "}")
  else
    workspace = "{:extensions [\".fnl\" \".fnlm\"] :dotfiles false :symlinks false :paths [\".\"]}"
  end
  local format
  if workspace_3f then
    format = "{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings false :maps false :clauses false :split-bindings false :collapse-padding false :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]}}"
  else
    format = ("{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings false :maps false :clauses false :split-bindings false :collapse-padding false :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]} " .. body .. "}")
  end
  return ("{:workspace " .. workspace .. " :format " .. format .. " :lint {:rules {}}}")
end
local function run_cli(root, args)
  local lines = {}
  local cli = load_cli()
  if cli["module-missing"] then
    return cli
  else
    local function _13_(line)
      return table.insert(lines, line)
    end
    return {code = cli.run(args, {cwd = root, print = _13_}), lines = lines}
  end
end
local function check_scenario_result(root, path, expected_code, expected_lines)
  local result = run_cli(root, {"format", "--check", "a.fnl"})
  return {code = result.code, lines = result.lines, content = read_file(path), ["expected-code"] = expected_code, ["expected-lines"] = expected_lines}
end
local function check_scenario_body(root, path, source, expected_code, expected_lines)
  write_file((root .. "/.fnl-extras.fnl"), format_config(""))
  write_file(path, source)
  return check_scenario_result(root, path, expected_code, expected_lines)
end
local function check_scenario(source, expected_code, expected_lines)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _15_()
    return vim.fn.delete(root, "rf")
  end
  local function _16_()
    return check_scenario_body(root, path, source, expected_code, expected_lines)
  end
  return with_cleanup(_15_, _16_)
end
local function write_good_scenario(root, good)
  local _ = write_file(good, "(when x\ny)\n")
  local result = run_cli(root, {"format", "--write", "--parser", "eca.nfnl.fennel", "good.fnl"})
  return {code = result.code, lines = result.lines, good = read_file(good)}
end
local function write_formatted_scenario(root, good)
  local _ = write_file(good, "(when x\n  y)\n")
  local result = run_cli(root, {"format", "--write", "good.fnl"})
  return {code = result.code, lines = result.lines, good = read_file(good), ["entry-count"] = #vim.fn.globpath(root, "*", false, true)}
end
local function write_error_scenario(root, good, bad)
  local _ = write_file(good, "(when x\ny)\n")
  local _0 = write_file(bad, "(x")
  local result = run_cli(root, {"format", "--write", "good.fnl", "bad.fnl"})
  return {code = result.code, lines = result.lines, good = read_file(good), bad = read_file(bad)}
end
local function write_scenario_body(root, good, bad, mode)
  write_file((root .. "/.fnl-extras.fnl"), format_config(""))
  return (((mode == "good") and write_good_scenario(root, good)) or ((mode == "formatted") and write_formatted_scenario(root, good)) or write_error_scenario(root, good, bad))
end
local function write_scenario(mode)
  local root = vim.fn.tempname()
  local good = (root .. "/good.fnl")
  local bad = (root .. "/bad.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _17_()
    return vim.fn.delete(root, "rf")
  end
  local function _18_()
    return write_scenario_body(root, good, bad, mode)
  end
  return with_cleanup(_17_, _18_)
end
local function config_indent_scenario(root, src_file, config_path)
  local _ = write_file(config_path, format_config(":indents {\"deftest\" [[:block 1]]}"))
  local _0 = write_file(src_file, "(deftest t\n(foo))\n")
  local result = run_cli(root, {"format", "--write", "src/a.fnl"})
  return {code = result.code, lines = result.lines, content = read_file(src_file)}
end
local function config_exclude_scenario(root, src_file, skip_file, config_path)
  local _ = write_file(config_path, format_config(":exclude [\"skip\"]"))
  local _0 = write_file(src_file, "(when x\n  y)\n")
  local _1 = write_file(skip_file, "(when x\ny)\n")
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, lines = result.lines, content = read_file(skip_file)}
end
local function config_paths_scenario(root, src_file, skip_file, config_path)
  local _ = write_file(config_path, format_config(":paths [\"src\"]"))
  local _0 = write_file(src_file, "(when x\ny)\n")
  local _1 = write_file(skip_file, "(when x\ny)\n")
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, lines = result.lines, src = read_file(src_file), skip = read_file(skip_file)}
end
local function config_invalid_scenario(root, src_file, config_path)
  local _ = write_file(config_path, "{:workspace {:paths [\".\"] :extensions [\".fnl\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} :lint {:rules {}} :colour 1}")
  local result = run_cli(root, {"format", "--check", "src/a.fnl"})
  return {code = result.code, lines = result.lines}
end
local function config_scenario_body(mode, root, src_file, skip_file, config_path)
  return (((mode == "indent") and config_indent_scenario(root, src_file, config_path)) or ((mode == "exclude") and config_exclude_scenario(root, src_file, skip_file, config_path)) or ((mode == "paths") and config_paths_scenario(root, src_file, skip_file, config_path)) or config_invalid_scenario(root, src_file, config_path))
end
local function config_scenario(mode)
  local root = vim.fn.tempname()
  local src = (root .. "/src")
  local skip = (root .. "/skip")
  local src_file = (src .. "/a.fnl")
  local skip_file = (skip .. "/x.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(src, "p")
  vim.fn.mkdir(skip, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _19_()
    return vim.fn.delete(root, "rf")
  end
  local function _20_()
    return config_scenario_body(mode, root, src_file, skip_file, config_path)
  end
  return with_cleanup(_19_, _20_)
end
local function align_bindings_cli_scenario_result(root, path, expected)
  local check_result = run_cli(root, {"format", "--check", "a.fnl"})
  local write_result = run_cli(root, {"format", "--write", "a.fnl"})
  return {["check-code"] = check_result.code, ["check-lines"] = check_result.lines, ["write-code"] = write_result.code, ["write-lines"] = write_result.lines, content = read_file(path), expected = expected}
end
local function align_bindings_cli_scenario_body(root, path, config_path, source, expected)
  write_file(config_path, "{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"lambda\" [[:inner 0]] \"macro\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"when-let\" [[:block 1]] \"if-let\" [[:block 1]] \"each\" [[:block 1]] \"for\" [[:block 1]] \"icollect\" [[:block 1]] \"collect\" [[:block 1]] \"accumulate\" [[:block 1]] \"case\" [[:block 1]] \"match\" [[:block 1]] \"case-try\" [[:block 1]] \"match-try\" [[:block 1]] \"while\" [[:block 1]] \"with-open\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings true :maps true :clauses true :split-bindings true :collapse-padding true :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]}}")
  write_file(path, source)
  return align_bindings_cli_scenario_result(root, path, expected)
end
local function align_bindings_cli_scenario()
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  local source = "(let [a 1\n      long-name 2]\n  a)"
  local expected = "(let [a         1\n      long-name 2]\n  a)"
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _21_()
    return vim.fn.delete(root, "rf")
  end
  local function _22_()
    return align_bindings_cli_scenario_body(root, path, config_path, source, expected)
  end
  return with_cleanup(_21_, _22_)
end
local function _23_()
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, content = "(when x\n  y)\n", ["expected-code"] = 0, ["expected-lines"] = {}}
    local actual_7_auto = check_scenario("(when x\n  y)\n", 0, {})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns zero and no lines for an already-formatted project", _24_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, content = "(when x\ny)\n", ["expected-code"] = 1, ["expected-lines"] = {"a.fnl"}}
    local actual_7_auto = check_scenario("(when x\ny)\n", 1, {"a.fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns one and leaves an unformatted file unchanged", _25_)
end
require("plenary.busted").describe("cli-check", _23_)
local function _26_()
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"good.fnl"}, good = "(when x\n  y)\n"}
    local actual_7_auto = write_scenario("good")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rewrites an unformatted file and reports its relative path", _27_)
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, good = "(when x\n  y)\n", ["entry-count"] = 1}
    local actual_7_auto = write_scenario("formatted")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not rewrite an already-formatted file or leave a temp file", _28_)
  local function _29_()
    local result = write_scenario("error")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and ("(when x\ny)\n" == result.good) and ("(x" == result.bad) and (1 == #result.lines) and string.match(result.lines[1], "^bad%.fnl:[0-9]+:[0-9]+: .*"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (= \"(when x\ny)\n\" (. result \"good\")) (= \"(x\" (. result \"bad\")) (= 1 (length (. result \"lines\"))) (string.match (. result \"lines\" 1) \"^bad%.fnl:[0-9]+:[0-9]+: .*\"))")
    return true
  end
  return require("plenary.busted").it("formats all files before writing and leaves the good file unchanged on error", _29_)
end
require("plenary.busted").describe("write", _26_)
local function _30_()
  local function _31_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"src/a.fnl"}, content = "(deftest t\n  (foo))\n"}
    local actual_7_auto = config_scenario("indent")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured indentation rules", _31_)
  local function _32_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, content = "(when x\ny)\n"}
    local actual_7_auto = config_scenario("exclude")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("skips files under configured exclude prefixes", _32_)
  local function _33_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"src/a.fnl"}, src = "(when x\n  y)\n", skip = "(when x\ny)\n"}
    local actual_7_auto = config_scenario("paths")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured paths for a no-argument run", _33_)
  local function _34_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, ["line-count"] = 1, ["mentions-config"] = true}
    local actual_7_auto
    do
      local result = config_scenario("invalid")
      local lines = (result.lines or {})
      local line = (lines[1] or "")
      actual_7_auto = {code = result.code, ["line-count"] = #lines, ["mentions-config"] = not not string.match(line, "fnl%-extras")}
    end
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns one config error line for an invalid configuration", _34_)
end
require("plenary.busted").describe("config", _30_)
local function extension_fnl_scenario(root, path, config_path)
  local _ = write_file(path, "(when x\ny)\n")
  local _0 = write_file((root .. "/source.fnlm"), "(when y\nz)\n")
  local result = run_cli(root, {"format", "--check"})
  return {code = result.code, lines = result.lines}
end
local function extension_other_scenario(root, path, config_path)
  local _ = write_file(path, "(when x\ny)\n")
  local result = run_cli(root, {"format", "--check"})
  return {code = result.code, lines = result.lines}
end
local function extension_scenario_body(extension, root, path, config_path)
  write_file(config_path, format_config((":extensions [\"" .. extension .. "\"]")))
  return (((extension == ".fnl") and extension_fnl_scenario(root, path, config_path)) or extension_other_scenario(root, path, config_path))
end
local function extension_scenario(extension)
  local root = vim.fn.tempname()
  local path = (root .. "/source" .. extension)
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _35_()
    return vim.fn.delete(root, "rf")
  end
  local function _36_()
    return extension_scenario_body(extension, root, path, config_path)
  end
  return with_cleanup(_35_, _36_)
end
local function default_path_scenario()
  local root = vim.fn.tempname()
  local path = (root .. "/source.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _37_()
    return vim.fn.delete(root, "rf")
  end
  local function _38_()
    write_file(path, "(when x\ny)\n")
    local result = run_cli(root, {"format", "--write"})
    return {code = result.code, lines = result.lines, content = read_file(path)}
  end
  return with_cleanup(_37_, _38_)
end
local function dotfiles_scenario_setup(root, hidden_file, nested_file, git_file)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":paths [\"fnl\"] :dotfiles false"))
  write_file(hidden_file, "(when x\ny)\n")
  write_file(nested_file, "(when x\ny)\n")
  return write_file(git_file, "(when x\ny)\n")
end
local function dotfiles_scenario_body(root, hidden_file, nested_file, git_file)
  local _ = dotfiles_scenario_setup(root, hidden_file, nested_file, git_file)
  local result = run_cli(root, {"format", "--check"})
  return {code = result.code, lines = result.lines, hidden = vim.loop.fs_stat(hidden_file).type, nested = vim.loop.fs_stat(nested_file).type, git = read_file(git_file)}
end
local function dotfiles_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local hidden_dir = (fnl_dir .. "/.hidden")
  local hidden_file = (fnl_dir .. "/.hidden.fnl")
  local nested_file = (hidden_dir .. "/nested.fnl")
  local git_dir = (fnl_dir .. "/.git")
  local git_file = (git_dir .. "/ignored.fnl")
  vim.fn.mkdir(hidden_dir, "p")
  vim.fn.mkdir(git_dir, "p")
  local function _39_()
    return vim.fn.delete(root, "rf")
  end
  local function _40_()
    return dotfiles_scenario_body(root, hidden_file, nested_file, git_file)
  end
  return with_cleanup(_39_, _40_)
end
local function follow_symlink_scenario_setup(root, link, target)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":paths [\"fnl\"] :symlinks true"))
  write_file(target, "(when x\ny)\n")
  return assert(vim.loop.fs_symlink(target, link))
end
local function follow_symlink_scenario_body(root, outside, link, target)
  local _ = follow_symlink_scenario_setup(root, link, target)
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
end
local function follow_symlink_scenario()
  local root = vim.fn.tempname()
  local outside = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local link = (fnl_dir .. "/link.fnl")
  local target = (outside .. "/outside.fnl")
  vim.fn.mkdir(fnl_dir, "p")
  vim.fn.mkdir(outside, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _41_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _42_()
    return follow_symlink_scenario_body(root, outside, link, target)
  end
  return with_cleanup(_41_, _42_)
end
local function follow_directory_symlink_check_result(root, target)
  local result = run_cli(root, {"format", "--check"})
  return {code = result.code, lines = result.lines, target = read_file(target)}
end
local function follow_directory_symlink_write_result(root, link, target)
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
end
local function follow_directory_symlink_result(mode, root, link, target)
  return (((mode == "check") and follow_directory_symlink_check_result(root, target)) or follow_directory_symlink_write_result(root, link, target))
end
local function follow_directory_symlink_scenario_setup(root, link, target, outside)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":symlinks true"))
  write_file(target, "(when x\ny)\n")
  return assert(vim.loop.fs_symlink(outside, link))
end
local function follow_directory_symlink_scenario_body(mode, root, link, target, outside)
  local _ = follow_directory_symlink_scenario_setup(root, link, target, outside)
  return follow_directory_symlink_result(mode, root, link, target)
end
local function follow_directory_symlink_scenario(mode)
  local root = vim.fn.tempname()
  local outside = vim.fn.tempname()
  local link = (root .. "/linkdir")
  local target = (outside .. "/a.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir(outside, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _43_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _44_()
    return follow_directory_symlink_scenario_body(mode, root, link, target, outside)
  end
  return with_cleanup(_43_, _44_)
end
local function parser_scenario_setup(path, config_path)
  write_file(path, "(when x\ny)\n")
  return write_file(config_path, format_config(":parser \"missing.parser.module\""))
end
local function parser_scenario_args(mode)
  if (mode == "config") then
    return {"format", "--check", "a.fnl"}
  else
    return {"format", "--check", "--parser", "eca.nfnl.fennel", "a.fnl"}
  end
end
local function parser_scenario_body(mode, root, path, config_path)
  local _ = parser_scenario_setup(path, config_path)
  local result = run_cli(root, parser_scenario_args(mode))
  return {code = result.code, lines = result.lines}
end
local function parser_scenario(mode)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _46_()
    return vim.fn.delete(root, "rf")
  end
  local function _47_()
    return parser_scenario_body(mode, root, path, config_path)
  end
  return with_cleanup(_46_, _47_)
end
local function rule_config_scenario_setup(path, config_path, config, source)
  write_file(config_path, format_config(config))
  return write_file(path, source)
end
local function rule_config_scenario_body(root, path, config_path, config, source, expected)
  local _ = rule_config_scenario_setup(path, config_path, config, source)
  local result = run_cli(root, {"format", "--write", "a.fnl"})
  return {code = result.code, lines = result.lines, content = read_file(path), expected = expected}
end
local function rule_config_scenario(config, source, expected)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _48_()
    return vim.fn.delete(root, "rf")
  end
  local function _49_()
    return rule_config_scenario_body(root, path, config_path, config, source, expected)
  end
  return with_cleanup(_48_, _49_)
end
local function config_discovery_scenario_setup(mode, config_path, source_path)
  local function _51_()
    if (mode == "mixed") then
      return (string.gsub(format_config(":dotfiles false"), " :format ", "\n:format ") .. "\n")
    else
      if ((mode == "enabled") or (mode == "enabled-mixed")) then
        return ("{:workspace {:config true}\n" .. ":format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false}\n" .. ":lint {:rules {}}}\n")
      else
        return format_config(":dotfiles false")
      end
    end
  end
  write_file(config_path, _51_())
  return write_file(source_path, "(when x\ny)\n")
end
local function config_discovery_scenario_args(mode)
  if (mode == "check") then
    return {"format", "--check"}
  else
    if (mode == "explicit") then
      return {"format", "--check", ".fnl-extras.fnl"}
    else
      if ((mode == "mixed") or (mode == "enabled-mixed")) then
        return {"format", "--check", ".fnl-extras.fnl", "a.fnl"}
      else
        return {"format", "--write"}
      end
    end
  end
end
local function config_discovery_scenario_body(mode, root, config_path, source_path)
  local _ = config_discovery_scenario_setup(mode, config_path, source_path)
  local result = run_cli(root, config_discovery_scenario_args(mode))
  return {code = result.code, lines = result.lines, config = read_file(config_path), source = read_file(source_path)}
end
local function config_discovery_scenario(mode)
  local root = vim.fn.tempname()
  local config_path = (root .. "/.fnl-extras.fnl")
  local source_path = (root .. "/a.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _55_()
    return vim.fn.delete(root, "rf")
  end
  local function _56_()
    return config_discovery_scenario_body(mode, root, config_path, source_path)
  end
  return with_cleanup(_55_, _56_)
end
local function _57_()
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"source.fnl"}}
    local actual_7_auto = extension_scenario(".fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses only configured extensions during discovery", _58_)
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"source.fnlx"}}
    local actual_7_auto = extension_scenario(".fnlx")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("discovers a configured non-default extension", _59_)
  local function _60_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"config: missing .fnl-extras.fnl"}, content = "(when x\ny)\n"}
    local actual_7_auto = default_path_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("missing paths and config are reported instead of using a current-directory default", _60_)
  local function _61_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"no files found"}, hidden = "file", nested = "file", git = "(when x\ny)\n"}
    local actual_7_auto = dotfiles_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("skips dotfiles and dot-directories when dotfiles is false and never .git", _61_)
  local function _62_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"fnl/link.fnl"}, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_symlink_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("follows file symlinks to real targets and preserves the symlink", _62_)
  local function _63_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"linkdir/a.fnl"}, target = "(when x\ny)\n"}
    local actual_7_auto = follow_directory_symlink_scenario("check")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports files under followed directory symlinks by logical path", _63_)
  local function _64_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_directory_symlink_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("writes files under followed directory symlinks to their real targets", _64_)
  local function _65_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"could not require parser module: missing.parser.module"}}
    local actual_7_auto = parser_scenario("config")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the parser named by config when no CLI parser is given", _65_)
  local function _66_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}}
    local actual_7_auto = parser_scenario("flag")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("CLI parser overrides the parser named by config", _66_)
end
require("plenary.busted").describe("cli-new-configuration", _57_)
local function symlink_loop_scenario_setup(root, file, loop_path)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":paths [\"fnl\"]"))
  write_file(file, "(when x\ny)\n")
  return assert(vim.loop.fs_symlink(root, loop_path))
end
local function symlink_loop_scenario_body(root, file, loop_path, script)
  local _ = symlink_loop_scenario_setup(root, file, loop_path)
  local command = ("cd " .. vim.fn.shellescape(root) .. " && perl -e 'alarm shift; exec @ARGV' 10 " .. vim.fn.shellescape(script) .. " format --check")
  local lines = vim.fn.systemlist({"sh", "-c", command})
  return {code = vim.v.shell_error, lines = lines}
end
local function symlink_loop_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local file = (fnl_dir .. "/a.fnl")
  local loop_path = (fnl_dir .. "/loop")
  local script = (vim.fn.getcwd() .. "/scripts/fennel-extras")
  vim.fn.mkdir(fnl_dir, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _67_()
    return vim.fn.delete(root, "rf")
  end
  local function _68_()
    return symlink_loop_scenario_body(root, file, loop_path, script)
  end
  return with_cleanup(_67_, _68_)
end
local function two_phase_skipped_scenario(probe_file, probe)
  local _ = probe_file:close()
  local _0 = vim.fn.delete(probe)
  return {["skipped-root"] = true}
end
local function two_phase_write_attempt(root, good)
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, ["a-unchanged"] = (read_file(good) == "(when x\ny)\n")}
end
local function two_phase_write_scenario_setup(root, good, blocked, read_only)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":paths [\"fnl\"]"))
  write_file(good, "(when x\ny)\n")
  write_file(blocked, "(when y\nz)\n")
  return vim.fn.setfperm(read_only, "r-xr-xr-x")
end
local function two_phase_write_scenario_body(root, read_only, good, blocked, probe)
  local _ = two_phase_write_scenario_setup(root, good, blocked, read_only)
  local probe_file = io.open(probe, "w")
  if probe_file then
    return two_phase_skipped_scenario(probe_file, probe)
  else
    return two_phase_write_attempt(root, good)
  end
end
local function two_phase_write_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local read_only = (fnl_dir .. "/ro")
  local good = (fnl_dir .. "/a.fnl")
  local blocked = (read_only .. "/b.fnl")
  local probe = (read_only .. "/probe")
  vim.fn.mkdir(read_only, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _70_()
    vim.fn.setfperm(read_only, "rwxr-xr-x")
    return vim.fn.delete(root, "rf")
  end
  local function _71_()
    return two_phase_write_scenario_body(root, read_only, good, blocked, probe)
  end
  return with_cleanup(_70_, _71_)
end
local function dotfile_config_scenario(root, fnl_dir)
  local _ = write_file((root .. "/.fnl-extras.fnl"), format_config(""))
  local _0 = write_file((fnl_dir .. "/a.fnl"), "(when x\n  y)\n")
  local result = run_cli(root, {"format", "--check", "."})
  return {code = result.code, lines = result.lines}
end
local function dotfile_source_scenario(root)
  local _ = write_file((root .. "/.x.fnl"), "(when x\n  y)\n")
  local result = run_cli(root, {"format", "--check", "."})
  return {code = result.code, lines = result.lines}
end
local function dotfile_scenario(mode)
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  vim.fn.mkdir(fnl_dir, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _72_()
    return vim.fn.delete(root, "rf")
  end
  local function _73_()
    if (mode == "config") then
      return dotfile_config_scenario(root, fnl_dir)
    else
      return dotfile_source_scenario(root)
    end
  end
  return with_cleanup(_72_, _73_)
end
local function symlink_file_scenario_setup(root, good, link, target)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":paths [\"fnl\"]"))
  write_file(good, "(when x\n  y)\n")
  write_file(target, "(when x\ny)\n")
  return assert(vim.loop.fs_symlink(target, link))
end
local function symlink_file_scenario_args(mode)
  if (mode == "write") then
    return {"format", "--write"}
  else
    return {"format", "--check", "fnl/link.fnl"}
  end
end
local function symlink_file_scenario_body(mode, root, good, link, target)
  local _ = symlink_file_scenario_setup(root, good, link, target)
  local result = run_cli(root, symlink_file_scenario_args(mode))
  return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
end
local function symlink_file_scenario(mode)
  local root = vim.fn.tempname()
  local outside = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local good = (fnl_dir .. "/a.fnl")
  local link = (fnl_dir .. "/link.fnl")
  local target = (outside .. "/outside.fnl")
  vim.fn.mkdir(fnl_dir, "p")
  vim.fn.mkdir(outside, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _76_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _77_()
    return symlink_file_scenario_body(mode, root, good, link, target)
  end
  return with_cleanup(_76_, _77_)
end
local function follow_symlink_dedupe_scenario_setup(root, target, link)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":symlinks true"))
  write_file(target, "(when x\ny)\n")
  return assert(vim.loop.fs_symlink(target, link))
end
local function follow_symlink_dedupe_scenario_body(root, target, link)
  local _ = follow_symlink_dedupe_scenario_setup(root, target, link)
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
end
local function follow_symlink_dedupe_scenario()
  local root = vim.fn.tempname()
  local target = (root .. "/a.fnl")
  local link = (root .. "/b.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _78_()
    return vim.fn.delete(root, "rf")
  end
  local function _79_()
    return follow_symlink_dedupe_scenario_body(root, target, link)
  end
  return with_cleanup(_78_, _79_)
end
local function follow_symlink_cycle_scenario_setup(root, file, loop_path)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":symlinks true"))
  write_file(file, "(when x\ny)\n")
  return assert(vim.loop.fs_symlink(root, loop_path))
end
local function follow_symlink_cycle_scenario_body(root, file, loop_path)
  local _ = follow_symlink_cycle_scenario_setup(root, file, loop_path)
  local result = run_cli(root, {"format", "--check"})
  return {code = result.code, lines = result.lines}
end
local function follow_symlink_cycle_scenario()
  local root = vim.fn.tempname()
  local directory = (root .. "/d")
  local file = (directory .. "/x.fnl")
  local loop_path = (directory .. "/loop")
  vim.fn.mkdir(directory, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _80_()
    return vim.fn.delete(root, "rf")
  end
  local function _81_()
    return follow_symlink_cycle_scenario_body(root, file, loop_path)
  end
  return with_cleanup(_80_, _81_)
end
local function follow_symlink_explicit_scenario_setup(root, target, link)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":symlinks true"))
  write_file(target, "(when x\ny)\n")
  return assert(vim.loop.fs_symlink(target, link))
end
local function follow_symlink_explicit_scenario_body(root, target, link)
  local _ = follow_symlink_explicit_scenario_setup(root, target, link)
  local result = run_cli(root, {"format", "--check", "link.fnl"})
  return {code = result.code, lines = result.lines}
end
local function follow_symlink_explicit_scenario()
  local root = vim.fn.tempname()
  local target = (root .. "/real.fnl")
  local link = (root .. "/link.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _82_()
    return vim.fn.delete(root, "rf")
  end
  local function _83_()
    return follow_symlink_explicit_scenario_body(root, target, link)
  end
  return with_cleanup(_82_, _83_)
end
local function unreadable_directory_result(root)
  local result = run_cli(root, {"format", "--check"})
  local lines = result.lines
  return {code = result.code, ["mentions-read-error"] = not not string.match((lines[1] or ""), "cannot read directory")}
end
local function unreadable_directory_scenario_setup(root, locked, good)
  write_file((root .. "/.fnl-extras.fnl"), format_config(":paths [\"fnl\"]"))
  write_file(good, "(when x\n  y)\n")
  return vim.fn.setfperm(locked, "---------")
end
local function unreadable_directory_scenario_body(root, locked, good)
  local _ = unreadable_directory_scenario_setup(root, locked, good)
  local handle = vim.loop.fs_scandir(locked)
  if handle then
    return {["skipped-root"] = true}
  else
    return unreadable_directory_result(root)
  end
end
local function unreadable_directory_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local locked = (fnl_dir .. "/locked")
  local good = (fnl_dir .. "/a.fnl")
  vim.fn.mkdir(locked, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _85_()
    vim.fn.setfperm(locked, "rwxr-xr-x")
    return vim.fn.delete(root, "rf")
  end
  local function _86_()
    return unreadable_directory_scenario_body(root, locked, good)
  end
  return with_cleanup(_85_, _86_)
end
local function _87_()
  local function _88_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(when x\n    y)\n", expected = "(when x\n    y)\n"}
    local actual_7_auto = rule_config_scenario(":indent-width 4", "(when x\ny)\n", "(when x\n    y)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured indent-width", _88_)
  local function _89_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(let [x 1]\n     x)\n", expected = "(let [x 1]\n     x)\n"}
    local actual_7_auto = rule_config_scenario(":builtins false", "(let [x 1]\nx)\n", "(let [x 1]\n     x)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("disables built-in indentation rules when builtins is false", _89_)
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(defn x\n      y)\n", expected = "(defn x\n      y)\n"}
    local actual_7_auto = rule_config_scenario(":prefix-fallbacks false", "(defn x\ny)\n", "(defn x\n      y)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("disables prefix fallback indentation rules when prefix-fallbacks is false", _90_)
end
require("plenary.busted").describe("configured-formatting-rules", _87_)
local function _91_()
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, config = format_config(":dotfiles false"), source = "(when x\ny)\n"}
    local actual_7_auto = config_discovery_scenario("check")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report the discovered config file as a formatting target", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, config = format_config(":dotfiles false"), source = "(when x\n  y)\n"}
    local actual_7_auto = config_discovery_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not rewrite the discovered config file", _93_)
  local function _94_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, config = format_config(":dotfiles false"), source = "(when x\ny)\n"}
    local actual_7_auto = config_discovery_scenario("explicit")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formats an explicitly named config file", _94_)
  local function _95_()
    local result = config_discovery_scenario("mixed")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, source = "(when x\ny)\n"}
    local actual_7_auto = {code = result.code, lines = result.lines, source = result.source}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("removes the config file when explicit inputs are mixed", _95_)
  local function _96_()
    local result = config_discovery_scenario("enabled")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((0 == result.code) and string.match((result.lines[1] or ""), "fnl%-extras"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"fnl%-extras\"))")
    return true
  end
  require("plenary.busted").it("includes the config file when workspace config inclusion is enabled", _96_)
  local function _97_()
    local result = config_discovery_scenario("enabled-mixed")
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, config = "{:workspace {:config true}\n:format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false}\n:lint {:rules {}}}\n", source = "(when x\ny)\n"}
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("excludes the config file from mixed explicit inputs when inclusion is enabled", _97_)
end
require("plenary.busted").describe("config-file-discovery", _91_)
local function _98_()
  local function _99_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"fnl/a.fnl"}}
    local actual_7_auto = symlink_loop_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not recurse through directory symlinks", _99_)
  local function _100_()
    local result = two_phase_write_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto
    if result["skipped-root"] then
      expected_6_auto = {["skipped-root"] = true}
    else
      expected_6_auto = {code = 2, ["a-unchanged"] = true}
    end
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not partially write files when a later write fails", _100_)
  local function _102_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}}
    local actual_7_auto = dotfile_scenario("config")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not discover a dotfile config as source", _102_)
  local function _103_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"config: missing .fnl-extras.fnl"}}
    local actual_7_auto = dotfile_scenario("source")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a format command without a config file exits two", _103_)
  local function _104_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, ["link-type"] = "link", target = "(when x\ny)\n"}
    local actual_7_auto = symlink_file_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("skips symlinked files during no-argument writes", _104_)
  local function _105_()
    local result = symlink_file_scenario("check")
    local lines = result.lines
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, ["line-count"] = 1, ["mentions-symlink"] = true}
    local actual_7_auto = {code = result.code, ["line-count"] = #lines, ["mentions-symlink"] = not not string.match((lines[1] or ""), "symlink")}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an explicit symlink file argument", _105_)
  local function _106_()
    local result = unreadable_directory_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto
    if result["skipped-root"] then
      expected_6_auto = {["skipped-root"] = true}
    else
      expected_6_auto = {code = 2, ["mentions-read-error"] = true}
    end
    local actual_7_auto = result
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports an unreadable directory", _106_)
  local function _108_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_symlink_dedupe_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("processes a real file only once when a symlink points to it", _108_)
  local function _109_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"d/x.fnl"}}
    local actual_7_auto = follow_symlink_cycle_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("terminates when a followed directory symlink forms a cycle", _109_)
  local function _110_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"link.fnl"}}
    local actual_7_auto = follow_symlink_explicit_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("follows an explicitly named symlink file", _110_)
end
require("plenary.busted").describe("edge-cases", _98_)
local function lint_git_command(root, args)
  local escaped_args
  local _111_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, arg in ipairs(args) do
      local val_28_ = vim.fn.shellescape(arg)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _111_ = tbl_26_
  end
  escaped_args = table.concat(_111_, " ")
  local command = ("cd " .. vim.fn.shellescape(root) .. " && perl -e 'alarm shift; exec @ARGV' 30 git " .. escaped_args .. " </dev/null 2>&1")
  vim.fn.systemlist({"sh", "-c", command})
  return vim.v.shell_error
end
local function lint_git_init(root)
  lint_git_command(root, {"init", "-q"})
  lint_git_command(root, {"config", "user.email", "a@b"})
  lint_git_command(root, {"config", "user.name", "t"})
  lint_git_command(root, {"config", "commit.gpgsign", "false"})
  lint_git_command(root, {"config", "tag.gpgsign", "false"})
  return root
end
local function lint_git_commit(root)
  lint_git_command(root, {"add", "."})
  lint_git_command(root, {"commit", "-qm", "base"})
  return root
end
local lint_rule_options = {["module-style"] = ":applies-to {:files [\"^[^s]\"] :modules \"eca.nfnl.macros.aniseed\" :forms [\"module\" \"def\" \"defn\" \"defn-\"]} :options {}", ["module-import"] = ":applies-to {:modules \"eca.nfnl.core\"} :options {:binding \"core\"}", ["forbidden-form"] = ":applies-to {:files [\"^[^s]\"] :forms [\"var\" \"set\" \"while\"]} :options {}", ["form-child-count"] = ":applies-to {:forms [\"testing\"]} :options {:children [\"is\"] :max-count 1}", ["if-branch-call"] = ":applies-to {:forms [\"if\"]} :options {}", ["if-without-else"] = ":applies-to {:forms [\"if\"]} :options {:nil-else true}", ["control-layout"] = ":applies-to {:forms [\"if\" \"when\" \"and\" \"or\" \"case\" \"match\"]} :options {}", ["function-shape"] = ":applies-to {:forms [\"defn\" \"defn-\" \"fn\" \"lambda\" \"\206\187\"]} :options {}", ["file-size"] = ":applies-to {:files [\"^[^s]\"]} :options {:max-code-lines 300}", ["unused-and-or"] = ":applies-to {:forms [\"and\" \"or\"]} :options {}", ["split-bindings"] = ":applies-to {:forms [\"let\" \"when-let\" \"if-let\" \"with-open\"]} :options {}", ["call-data-arg"] = ":applies-to {:files [\"^[^s]\"] :forms []} :options {}"}
local design_rule_names = {["function-shape"] = true, ["if-branch-call"] = true, ["if-without-else"] = true, ["no-mutation"] = true, ["nested-forms"] = true, ["leading-bindings"] = true}
local function lint_config_rule(normalized, rule, options)
  local escaped_rule = string.gsub(rule, "-", "%%-")
  local warning_pattern = ("\"" .. escaped_rule .. "\"%s*:%s*warning")
  local warning_replacement = ("\"" .. rule .. "\" [{:severity :warning :applies-to {} :options {" .. options .. "} :exclusions []}]")
  local error_pattern = ("\"" .. escaped_rule .. "\"%s*:%s*error")
  local error_replacement = ("\"" .. rule .. "\" [{:severity :error :applies-to {} :options {" .. options .. "} :exclusions []}]")
  local off_pattern = ("\"" .. escaped_rule .. "\"%s*:%s*off")
  local off_replacement = ("\"" .. rule .. "\" [{:severity :off :applies-to {} :options {} :exclusions []}]")
  local normalized0 = string.gsub(normalized, warning_pattern, warning_replacement)
  local normalized1 = string.gsub(normalized0, error_pattern, error_replacement)
  return string.gsub(normalized1, off_pattern, off_replacement)
end
local function lint_config_rules(config)
  local normalized = config
  for rule, options in pairs(lint_rule_options) do
    normalized = lint_config_rule(normalized, rule, options)
    local escaped_rule = string.gsub(rule, "-", "%%-")
    normalized = string.gsub(normalized, ("\"" .. escaped_rule .. "\""), (":" .. rule))
  end
  return normalized
end
local function fennel_string(value)
  return string.format("%q", value)
end
local fennel_sequence_keys = {forms = true, children = true, modules = true, ["exempt-files"] = true, exclusions = true, paths = true, exclude = true, extensions = true, ["binding-forms"] = true, ["clause-forms"] = true}
local function fennel_value(value, as_list_3f)
  if ("table" == type(value)) then
    local list_3f = (as_list_3f or ((#value > 0) and vim.islist(value)))
    local parts = {}
    for key, item in pairs(value) do
      local function _115_()
        if list_3f then
          return fennel_value(item)
        else
          local _113_
          if (("string" == type(item)) and ((key == "severity") or (key == "mode"))) then
            _113_ = (":" .. item)
          else
            _113_ = fennel_value(item, fennel_sequence_keys[key])
          end
          return (":" .. key .. " " .. _113_)
        end
      end
      table.insert(parts, _115_())
    end
    local _116_
    if list_3f then
      _116_ = "["
    else
      _116_ = "{"
    end
    local _118_
    if list_3f then
      _118_ = "]"
    else
      _118_ = "}"
    end
    return (_116_ .. table.concat(parts, " ") .. _118_)
  else
    if ("string" == type(value)) then
      return fennel_string(value)
    else
      return tostring(value)
    end
  end
end
local function lint_config_finish(config)
  local config_module = require("fennel-extras.config")
  local parsed_result = config_module["parse-string"](config)
  if (nil == parsed_result) then
    return config
  else
    local lint = (parsed_result.lint or {})
    local rules = (lint.rules or {})
    local design = (parsed_result.design or {})
    local design_rules = (design.rules or {})
    local lint_rules = {}
    for rule, value in pairs(rules) do
      if design_rule_names[rule] then
        design_rules[rule] = value
      else
        lint_rules[rule] = value
      end
    end
    return fennel_value(vim.tbl_extend("force", parsed_result, {lint = vim.tbl_extend("force", lint, {rules = lint_rules}), design = vim.tbl_extend("force", design, {rules = design_rules})}), false)
  end
end
local function lint_config(config)
  local config0 = string.gsub(config, "^{%s*", "{:workspace {:extensions [\".fnl\"] :paths [\"\"]} :format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false} ")
  local normalized = lint_config_rules(config0)
  return lint_config_finish(normalized)
end
local function lint_project_write_file(root, before, path, text)
  local full = (root .. "/" .. path)
  vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
  write_file(full, text)
  before[path] = read_file(full)
  return nil
end
local function lint_project_prepare(root, config_path, config, files, before)
  lint_git_init(root)
  write_file(config_path, lint_config(config))
  for path, text in pairs(files) do
    lint_project_write_file(root, before, path, text)
  end
  return nil
end
local function lint_project_result(root, files, args, before, after)
  local result = run_cli(root, args)
  for path, _ in pairs(files) do
    after[path] = read_file((root .. "/" .. path))
  end
  return {code = result.code, lines = result.lines, before = before, after = after}
end
local function lint_project_body(root, config_path, before, after, config, files, args)
  lint_project_prepare(root, config_path, config, files, before)
  return lint_project_result(root, files, args, before, after)
end
local function lint_project(config, files, args)
  local root = vim.fn.tempname()
  local config_path = (root .. "/.fnl-extras.fnl")
  local before = {}
  local after = {}
  vim.fn.mkdir(root, "p")
  local function _124_()
    return vim.fn.delete(root, "rf")
  end
  local function _125_()
    return lint_project_body(root, config_path, before, after, config, files, args)
  end
  return with_cleanup(_124_, _125_)
end
local function lint_grammar_scenario(args)
  return lint_project("{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}", {["a.fnl"] = "(if x 1 2)\n"}, args)
end
local function lint_opt_in_scenario()
  return lint_project("{:lint {:rules {}}}", {["a.fnl"] = "(if x (do (foo) (bar)) nil)\n"}, {"lint", "--all"})
end
local function lint_discovery_scenario(mode)
  local config = "{:workspace {:paths [\"src\"] :exclude [\"src/skip\"] :extensions [\".fnl\"]} :lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}"
  local files = {["src/keep.fnl"] = "(if x 1 2)\n", ["src/skip/no.fnl"] = "(if x 1 2)\n", ["other.fnl"] = "(if x 1 2)\n"}
  local function _126_()
    if (mode == "default") then
      return {"lint", "--all"}
    else
      return {"lint", "--all", "src/keep.fnl"}
    end
  end
  return lint_project(config, files, _126_())
end
local function lint_config_discovery_scenario(mode)
  local root = vim.fn.tempname()
  local config_path = (root .. "/.fnl-extras.fnl")
  local config = "{:workspace {:paths [\".\"] :extensions [\".fnl\"] :config true}\n:format {:indent-width 2 :builtins false :prefix-fallbacks false :parser false}\n:lint {:rules {:file-size [{:severity :error :applies-to {} :options {:max-code-lines 1} :exclusions []}]}}}\n"
  vim.fn.mkdir(root, "p")
  local function _127_()
    return vim.fn.delete(root, "rf")
  end
  local function _128_()
    lint_git_init(root)
    write_file(config_path, config)
    write_file((root .. "/a.fnl"), "(when x\ny)\n")
    local result
    local function _129_()
      if (mode == "mixed") then
        return {"lint", "--all", ".fnl-extras.fnl", "a.fnl"}
      else
        return {"lint", "--all"}
      end
    end
    result = run_cli(root, _129_())
    local lines = (result.lines or {})
    return {code = result.code, lines = lines, ["mentions-config"] = not not string.match(table.concat(lines, "\n"), "fnl%-extras")}
  end
  return with_cleanup(_127_, _128_)
end
local function lint_output_config(mode)
  return (((mode == "error") and "{:lint {:rules {\"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}]}}}") or ((mode == "warning-error") and "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :error :applies-to {:forms [\"if\"]} :options {} :exclusions []}]}}}") or ((mode == "off") and "{:lint {:rules {\"module-style\" :off \"if-branch-call\" :off}}}") or "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}]}}}")
end
local function lint_output_source(mode)
  return (((mode == "error") and "(testing \"x\" (is 1) (is 2))\n") or "(if x (do (foo) (bar)) nil)\n")
end
local function lint_output_scenario(mode)
  return lint_project(lint_output_config(mode), {["a.fnl"] = lint_output_source(mode)}, {"lint", "--all"})
end
local function lint_exclusion_config(mode)
  return (((mode == "stale") and "{:lint {:rules {\"module-style\" :off}}\n             :design {:rules {:if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}") or "{:lint {:rules {\"module-style\" :off}}\n        :design {:rules {:if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions [{:path \"a.fnl\" :reason \"intentional multi-step branch\"}]}]}}}")
end
local function lint_exclusion_scenario(mode)
  return lint_project(lint_exclusion_config(mode), {["a.fnl"] = "(if x (do (foo) (bar)) nil)\n"}, {"lint", "--all"})
end
local function lint_normalized_testing_exclusion_scenario()
  return lint_project("{:lint {:rules {\"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions [{:path \"a.fnl\" :reason \"intentional test shape\"}]}]}}}", {["a.fnl"] = "(testing \"two\" (is true) (is true))\n"}, {"lint", "--all"})
end
local function lint_selector_exclusion_config(mode)
  return (((mode == "per-rule") and "{:lint {:rules {\"module-style\" :off}}\n             :design {:rules {:if-without-else [{:severity :warning :applies-to {:forms [\"if\"]} :options {:nil-else true} :exclusions [{:path \"a.fnl\" :reason \"intentional per-rule exclusion\"}]}]}}}") or "{:lint {:rules {}}\n        :design {:rules {:if-without-else [{:severity :warning :applies-to {:forms [\"if\"]} :options {:nil-else true} :exclusions [{:path \"a.fnl\" :reason \"intentional per-instance exclusion\"}]}]}}}")
end
local function lint_selector_exclusion_scenario(mode)
  return lint_project(lint_selector_exclusion_config(mode), {["a.fnl"] = "(if ok then)\n"}, {"lint", "--all"})
end
local function lint_invalid_regex_scenario()
  return lint_project("{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions [{:path \"[\" :reason \"bad regex\"]}]}}}", {["a.fnl"] = "(if\n"}, {"lint", "--all"})
end
local function lint_stale_pattern_scenario()
  return lint_project("{:lint {:rules {\"module-style\" :off}}\n                :design {:rules {:if-without-else [{:severity :warning :applies-to {:forms [\"if\"]} :options {:nil-else true} :exclusions [{:path \"missing[.]fnl\" :reason \"stale pattern\"]}]}}}", {["a.fnl"] = "(if ok then)\n"}, {"lint", "--all"})
end
local function lint_disabled_exclusion_scenario()
  return lint_project("{:lint {:rules {}}\n                :design {:rules {:if-without-else [{:severity :off :applies-to {} :options {} :exclusions [{:path \"a.fnl\" :reason \"disabled rule\"]}]}}}", {["a.fnl"] = "(if ok then)\n"}, {"lint", "--all"})
end
local function lint_error_config(mode)
  if (mode == "config") then
    return "{:lint {:rules {:if-without-else [{:severity :warning :applies-to {} :options {:nope true} :exclusions []}]}}}"
  else
    return "{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}"
  end
end
local function lint_error_source(mode)
  return (((mode == "config") and "(if x 1 2)\n") or "(if x")
end
local function lint_error_scenario(mode)
  return lint_project(lint_error_config(mode), {["a.fnl"] = lint_error_source(mode)}, {"lint", "--all"})
end
local function _131_()
  local function _132_()
    local result = lint_opt_in_scenario()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}}
    local actual_7_auto = {code = result.code, lines = result.lines}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("omitting lint rules produces no findings", _132_)
  local function _133_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = lint_grammar_scenario({"lint", "--all"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts lint all with text output", _133_)
  local function _134_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = lint_grammar_scenario({"lint", "--all", "--format", "json"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts lint all with json output", _134_)
  local function _135_()
    local result = lint_grammar_scenario({"lint", "--all", "--base", "HEAD"})
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and string.match((result.lines[1] or ""), "base"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"base\"))")
    return true
  end
  require("plenary.busted").it("rejects base together with all with exit two and a clear message", _135_)
  local function _136_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--changed", "--all"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects changed together with all with exit two", _136_)
  local function _137_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--wat"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unknown flags with exit two", _137_)
  local function _138_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--all", "--all"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects duplicate flags with exit two", _138_)
  local function _139_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--format"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a missing format value with exit two", _139_)
  local function _140_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--format", "yaml"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an invalid format value with exit two", _140_)
  local function _141_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--write"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects formatter-only flags for lint", _141_)
  local function _142_()
    local function _143_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = lint_discovery_scenario("default").lines
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("uses configured paths exclusions extensions and omits its config file", _143_)
    local function _144_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = lint_discovery_scenario("explicit").lines
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("optional path arguments restrict lint all discovery", _144_)
    local function _145_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 1, ["mentions-config"] = true}
      local actual_7_auto
      do
        local result = lint_config_discovery_scenario("enabled")
        actual_7_auto = {code = result.code, ["mentions-config"] = result["mentions-config"]}
      end
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("includes the config file when workspace config inclusion is enabled", _145_)
    local function _146_()
      local result = lint_config_discovery_scenario("mixed")
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 1, lines = {"a.fnl:1:1: error file-size: file has 2 code lines (max 1); split it by responsibility into smaller modules", "  exclusion: {:rule \"file-size\" :form \"a.fnl > file\" :reason \"explain why this is intentional\"}"}, ["mentions-config"] = false}
      local actual_7_auto = {code = result.code, lines = result.lines, ["mentions-config"] = result["mentions-config"]}
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("excludes the config file from mixed explicit inputs when inclusion is enabled", _146_)
    local function _147_()
      local function _148_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 1
        local actual_7_auto = lint_output_scenario("error").code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("reports one error finding with text output and exit one", _148_)
      local function _149_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {"a.fnl:1:1: error form-child-count: each testing form must contain exactly one is", "  exclusion: {:rule \"form-child-count\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"}
        local actual_7_auto = lint_output_scenario("error").lines
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("prints the exact text line and exclusion suggestion for an error", _149_)
      local function _150_()
        local result = lint_output_scenario("warning")
        local assert_28_auto = require("luassert")
        local value_29_auto = ((0 == result.code) and (nil ~= result.lines[1]))
        assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (not= nil (. result \"lines\" 1)))")
        return true
      end
      require("plenary.busted").it("prints a warning but exits zero", _150_)
      local function _151_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 1
        local actual_7_auto = lint_output_scenario("warning-error").code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("turns the warning into an error when configured", _151_)
      local function _152_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 0
        local actual_7_auto = lint_output_scenario("off").code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("turns the warning off when configured", _152_)
      local function _153_()
        local result = lint_project("{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}]}}}", {["a.fnl"] = "(if x (do (foo) (bar)) nil)\n"}, {"lint", "--all", "--format", "json"})
        local assert_28_auto = require("luassert")
        local value_29_auto = ((0 == result.code) and string.match((result.lines[1] or ""), "^%{"))
        assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"^%{\"))")
        return true
      end
      return require("plenary.busted").it("emits json lines with the same warning status", _153_)
    end
    require("plenary.busted").describe("lint-output", _147_)
    local function _154_()
      local function _155_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 0
        local actual_7_auto = lint_exclusion_scenario("matching").code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("suppresses a matching exclusion in all mode", _155_)
      local function _156_()
        local result = lint_exclusion_scenario("stale")
        local assert_5_auto = require("luassert")
        local expected_6_auto = 1
        local actual_7_auto = result.code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("reports an unmatched exclusion as a stale error in all mode", _156_)
      local function _157_()
        local result = lint_normalized_testing_exclusion_scenario()
        local assert_5_auto = require("luassert")
        local expected_6_auto = {code = 0, lines = {}}
        local actual_7_auto = {code = result.code, lines = result.lines}
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("suppresses normalized form-child-count identity without stale output", _157_)
      local function _158_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 0
        local actual_7_auto = lint_selector_exclusion_scenario("per-rule").code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("suppresses a per-rule exclusion end to end", _158_)
      local function _159_()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 0
        local actual_7_auto = lint_selector_exclusion_scenario("general").code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("suppresses a general exclusion end to end", _159_)
      local function _160_()
        local result = lint_invalid_regex_scenario()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 2
        local actual_7_auto = result.code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("rejects an invalid regex before scanning source", _160_)
      local function _161_()
        local result = lint_stale_pattern_scenario()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 2
        local actual_7_auto = result.code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("reports a stale pattern exclusion", _161_)
      local function _162_()
        local result = lint_disabled_exclusion_scenario()
        local assert_5_auto = require("luassert")
        local expected_6_auto = 2
        local actual_7_auto = result.code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("reports a disabled-rule exclusion as stale", _162_)
    end
    require("plenary.busted").describe("lint-exclusions", _154_)
    local function _163_()
      local function _164_()
        local result = lint_error_scenario("config")
        local assert_5_auto = require("luassert")
        local expected_6_auto = 2
        local actual_7_auto = result.code
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      require("plenary.busted").it("returns exit two with a malformed lint configuration error", _164_)
      local function _165_()
        local result = lint_error_scenario("source")
        local assert_28_auto = require("luassert")
        local value_29_auto = ((2 == result.code) and string.match((result.lines[1] or ""), "a%.fnl:[0-9]+:[0-9]+:"))
        assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"a%.fnl:[0-9]+:[0-9]+:\"))")
        return true
      end
      require("plenary.busted").it("returns exit two with a source parse diagnostic", _165_)
      local function _166_()
        local result = lint_output_scenario("warning")
        local assert_5_auto = require("luassert")
        local expected_6_auto = result.before
        local actual_7_auto = result.after
        assert_5_auto.same(expected_6_auto, actual_7_auto)
        return true
      end
      return require("plenary.busted").it("does not change any file in all mode", _166_)
    end
    return require("plenary.busted").describe("lint-errors-and-read-only", _163_)
  end
  require("plenary.busted").describe("lint-discovery", _142_)
  local function shell_args(args)
    local _167_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, arg in ipairs(args) do
        local val_28_ = vim.fn.shellescape(arg)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _167_ = tbl_26_
    end
    return table.concat(_167_, " ")
  end
  local function real_cli_lines(root, args)
    local script = (vim.fn.getcwd() .. "/scripts/fennel-extras")
    local command = ("cd " .. vim.fn.shellescape(root) .. " && " .. vim.fn.shellescape(script) .. " " .. shell_args(args))
    return {code = vim.v.shell_error, lines = vim.fn.systemlist({"sh", "-c", (command .. " 2>/dev/null")})}
  end
  local function occurrence_count(text, needle, start)
    local index = string.find(text, needle, start, true)
    if index then
      return (1 + occurrence_count(text, needle, (index + 1)))
    else
      return 0
    end
  end
  local function one_json_object_per_line_3f(lines)
    local valid = true
    for _, line in ipairs(lines) do
      if (not string.match(line, "^%{.*%}$") or (1 ~= occurrence_count(line, "{\"kind\":", 1))) then
        valid = false
      else
      end
    end
    return valid
  end
  local function real_lint_output_setup(config, first_file, second_file, config_text, first_source, second_source)
    lint_git_init(vim.fn.fnamemodify(config, ":h"))
    write_file(config, lint_config(config_text))
    write_file(first_file, first_source)
    write_file(second_file, second_source)
    return lint_git_commit(vim.fn.fnamemodify(config, ":h"))
  end
  local function real_lint_output_result(root, format)
    local result = real_cli_lines(root, {"lint", "--all", "--format", format})
    local lines = result.lines
    return {lines = #lines, objects = 3, ["each-line-one-object?"] = one_json_object_per_line_3f(lines)}
  end
  local function real_text_lint_output_result(root)
    local result = real_cli_lines(root, {"lint", "--all"})
    return {lines = #result.lines, objects = 3}
  end
  local function real_lint_output_scenario(format)
    local root = vim.fn.tempname()
    local config = (root .. "/.fnl-extras.fnl")
    local first_file = (root .. "/a.fnl")
    local second_file = (root .. "/b.fnl")
    local config_text = "{:lint {:rules {\"module-import\" :off \"if-branch-call\" :off \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"
    local first_source = "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
    local second_source = "(testing \"c\" (is 1) (is 2))\\n"
    vim.fn.mkdir(root, "p")
    local function _171_()
      return vim.fn.delete(root, "rf")
    end
    local function _172_()
      real_lint_output_setup(config, first_file, second_file, config_text, first_source, second_source)
      return real_lint_output_result(root, format)
    end
    return with_cleanup(_171_, _172_)
  end
  local function real_text_lint_output_scenario()
    local root = vim.fn.tempname()
    local config = (root .. "/.fnl-extras.fnl")
    local first_file = (root .. "/a.fnl")
    local second_file = (root .. "/b.fnl")
    local config_text = "{:lint {:rules {\"module-import\" :off \"if-branch-call\" :off \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"
    local first_source = "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
    local second_source = "(testing \"c\" (is 1) (is 2))\\n"
    vim.fn.mkdir(root, "p")
    local function _173_()
      return vim.fn.delete(root, "rf")
    end
    local function _174_()
      real_lint_output_setup(config, first_file, second_file, config_text, first_source, second_source)
      return real_text_lint_output_result(root)
    end
    return with_cleanup(_173_, _174_)
  end
  local function _175_()
    local function _176_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {lines = 3, objects = 3, ["each-line-one-object?"] = true}
      local actual_7_auto = real_lint_output_scenario("json")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("prints one JSON object per physical line", _176_)
    local function _177_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {lines = 6, objects = 3}
      local actual_7_auto = real_text_lint_output_scenario()
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("prints each text finding and exclusion suggestion on its own line", _177_)
  end
  require("plenary.busted").describe("default-printer", _175_)
  local function bounded_command(command)
    local lines = vim.fn.systemlist({"sh", "-c", command})
    local code = vim.v.shell_error
    return {code = code, lines = lines, ["timed-out?"] = (code == 142)}
  end
  local function bounded_cli(root, args)
    local script = (vim.fn.getcwd() .. "/scripts/fennel-extras")
    local command = ("cd " .. vim.fn.shellescape(root) .. " && perl -e 'alarm shift; exec @ARGV' 30 " .. vim.fn.shellescape(script) .. " " .. shell_args(args) .. " </dev/null 2>&1")
    return bounded_command(command)
  end
  local function git_run(root, args)
    local command = ("cd " .. vim.fn.shellescape(root) .. " && perl -e 'alarm shift; exec @ARGV' 30 git " .. shell_args(args) .. " </dev/null 2>&1")
    return bounded_command(command).code
  end
  local function git_init(root)
    git_run(root, {"init", "-q"})
    git_run(root, {"config", "user.email", "a@b"})
    git_run(root, {"config", "user.name", "t"})
    git_run(root, {"config", "commit.gpgsign", "false"})
    git_run(root, {"config", "tag.gpgsign", "false"})
    return root
  end
  local function invalid_git_scenario_args(mode)
    return (((mode == "all") and {"lint", "--all"}) or {"lint", "--changed"})
  end
  local function invalid_git_scenario_body(mode, root)
    local _ = write_file((root .. "/.fnl-extras.fnl"), lint_config("{:lint {:rules {\"module-import\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}] \"module-style\" :off \"form-child-count\" :off \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"))
    local _0 = write_file((root .. "/a.fnl"), "(if x 1 2)\\n")
    local result = bounded_cli(root, invalid_git_scenario_args(mode))
    local line = (result.lines[1] or "")
    return {code = result.code, line = line, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  local function invalid_git_scenario(mode)
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, "p")
    vim.fn.mkdir((root .. "/.git"), "p")
    local function _178_()
      return vim.fn.delete(root, "rf")
    end
    local function _179_()
      return invalid_git_scenario_body(mode, root)
    end
    return with_cleanup(_178_, _179_)
  end
  local function unborn_git_scenario_body(mode, root)
    local _ = git_init(root)
    local _0 = write_file((root .. "/.fnl-extras.fnl"), lint_config("{:lint {:rules {\"module-import\" :off \"if-branch-call\" :off \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"))
    local _1 = write_file((root .. "/a.fnl"), "(testing \"x\") (import-macros {: testing : is} :spec.eca.macros)\n")
    local result = bounded_cli(root, invalid_git_scenario_args(mode))
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  local function unborn_git_scenario(mode)
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, "p")
    local function _180_()
      return vim.fn.delete(root, "rf")
    end
    local function _181_()
      return unborn_git_scenario_body(mode, root)
    end
    return with_cleanup(_180_, _181_)
  end
  local function changed_config()
    return "{:lint {:rules {\"module-import\" :off \"function-shape\" :off \"control-layout\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}] \"if-without-else\" :off \"module-style\" :off \"form-child-count\" :off \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"
  end
  local function changed_source(which)
    if (which == "changed") then
      return "(defn first []\n  (if z\n      (do\n        (foo)\n        (bar))\n      nil))\n\n(defn second []\n  (if y\n      (do\n        (baz)\n        (qux))\n      nil))\n"
    else
      return "(defn first []\n  (if x\n      (do\n        (foo)\n        (bar))\n      nil))\n\n(defn second []\n  (if y\n      (do\n        (baz)\n        (qux))\n      nil))\n"
    end
  end
  local function finding_lines(lines)
    local result = {}
    for _, line in ipairs(lines) do
      if not string.match(line, "^  ") then
        table.insert(result, line)
      else
      end
    end
    return result
  end
  local function both_source()
    return "(defn first []\n  (if z\n      (do\n        (foo)\n        (bar))\n      nil))\n\n(defn second []\n  (if q\n      (do\n        (baz)\n        (qux))\n      nil))\n"
  end
  local function changed_mode_both(root, source_path)
    local _ = write_file(source_path, changed_source("changed"))
    local _0 = git_run(root, {"add", "a.fnl"})
    return write_file(source_path, both_source())
  end
  local function changed_mode_staged(root, source_path)
    local _ = write_file(source_path, changed_source("changed"))
    return git_run(root, {"add", "a.fnl"})
  end
  local function changed_mode_rename(root)
    local _ = git_run(root, {"mv", "a.fnl", "renamed file.fnl"})
    return write_file((root .. "/renamed file.fnl"), changed_source("changed"))
  end
  local function changed_mode_setup(mode, root, source_path, config_path)
    git_init(root)
    write_file(config_path, lint_config(changed_config()))
    write_file(source_path, changed_source("base"))
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    if ((mode == "modified") or (mode == "subdir")) then
      write_file(source_path, changed_source("changed"))
    else
    end
    if (mode == "both") then
      changed_mode_both(root, source_path)
    else
    end
    if (mode == "staged") then
      changed_mode_staged(root, source_path)
    else
    end
    if (mode == "untracked") then
      write_file((root .. "/new file.fnl"), "(defn new [] (if z (do (foo) (bar)) nil))\n")
    else
    end
    if (mode == "rename") then
      return changed_mode_rename(root)
    else
      return nil
    end
  end
  local function changed_mode_cwd(mode, root, subdir)
    return (((mode == "subdir") and subdir) or root)
  end
  local function changed_mode_result(mode, root, subdir)
    local result = bounded_cli(changed_mode_cwd(mode, root, subdir), {"lint", "--changed"})
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  local function changed_mode_scenario_body(mode, root, source_path, config_path, subdir)
    local _ = changed_mode_setup(mode, root, source_path, config_path)
    return changed_mode_result(mode, root, subdir)
  end
  local function changed_mode_scenario(mode)
    local root = vim.fn.tempname()
    local source_path = (root .. "/a.fnl")
    local config_path = (root .. "/.fnl-extras.fnl")
    local subdir = (root .. "/nested")
    vim.fn.mkdir(root, "p")
    vim.fn.mkdir(subdir, "p")
    local function _189_()
      return vim.fn.delete(root, "rf")
    end
    local function _190_()
      return changed_mode_scenario_body(mode, root, source_path, config_path, subdir)
    end
    return with_cleanup(_189_, _190_)
  end
  local function base_mode_setup(root, source_path)
    git_init(root)
    write_file((root .. "/.fnl-extras.fnl"), lint_config(changed_config()))
    write_file(source_path, changed_source("base"))
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    write_file(source_path, changed_source("changed"))
    git_run(root, {"add", "."})
    return git_run(root, {"commit", "-qm", "changed"})
  end
  local function base_mode_scenario_body(root, source_path)
    local _ = base_mode_setup(root, source_path)
    local result = bounded_cli(root, {"lint", "--base", "HEAD~1"})
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  local function base_mode_scenario()
    local root = vim.fn.tempname()
    local source_path = (root .. "/a.fnl")
    vim.fn.mkdir(root, "p")
    local function _191_()
      return vim.fn.delete(root, "rf")
    end
    local function _192_()
      return base_mode_scenario_body(root, source_path)
    end
    return with_cleanup(_191_, _192_)
  end
  local function file_size_changed_mode_setup(root, changed_path, unchanged_path, config, base_source, changed_source0)
    git_init(root)
    write_file((root .. "/.fnl-extras.fnl"), lint_config(config))
    write_file(changed_path, base_source)
    write_file(unchanged_path, base_source)
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    return write_file(changed_path, changed_source0)
  end
  local function file_size_line(line, name)
    if string.match(line, name) then
      return line
    else
      return nil
    end
  end
  local function file_size_findings(findings, name)
    local _194_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, line in ipairs(findings) do
        local val_28_ = file_size_line(line, name)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _194_ = tbl_26_
    end
    return #_194_
  end
  local function file_size_changed_mode_scenario_body(root, changed_path, unchanged_path, config, base_source, changed_source0)
    local _ = file_size_changed_mode_setup(root, changed_path, unchanged_path, config, base_source, changed_source0)
    local result = bounded_cli(root, {"lint", "--changed"})
    local findings = finding_lines(result.lines)
    return {code = result.code, ["changed-file-size"] = file_size_findings(findings, "changed%.fnl:.*file%-size"), ["unchanged-file-size"] = file_size_findings(findings, "unchanged%.fnl:.*file%-size")}
  end
  local function file_size_changed_mode_scenario()
    local root = vim.fn.tempname()
    local changed_path = (root .. "/changed.fnl")
    local unchanged_path = (root .. "/unchanged.fnl")
    local config = "{:lint {:rules {\"module-import\" :off :file-size [{:severity :warning :applies-to {:files [\"^changed[.]fnl$\"]} :options { :max-code-lines 2} :exclusions []}] \"function-shape\" :off \"if-branch-call\" :off \"module-style\" :off \"forbidden-form\" :off \"form-child-count\" :off \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"
    local base_source = "(local a 1)\n(local b 2)\n(local c 3)\n"
    local changed_source0 = "(local a 9)\n(local b 2)\n(local c 3)\n"
    vim.fn.mkdir(root, "p")
    local function _196_()
      return vim.fn.delete(root, "rf")
    end
    local function _197_()
      return file_size_changed_mode_scenario_body(root, changed_path, unchanged_path, config, base_source, changed_source0)
    end
    return with_cleanup(_196_, _197_)
  end
  local function lint_error_repository_scenario(root)
    write_file((root .. "/.fnl-extras.fnl"), lint_config("{:lint {:rules {:module-style [{:severity :off :applies-to {} :options {} :exclusions []}]}}}"))
    return write_file((root .. "/a.fnl"), "(if x 1 2)\n")
  end
  local function lint_error_configured_scenario(root)
    local _ = git_init(root)
    local _0 = write_file((root .. "/.fnl-extras.fnl"), lint_config("{:lint {:rules {\"module-import\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}] \"module-style\" :off \"form-child-count\" :off \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"))
    local _1 = write_file((root .. "/a.fnl"), "(if x 1 2)\n")
    local _2 = git_run(root, {"add", "."})
    return git_run(root, {"commit", "-qm", "base"})
  end
  local function lint_error_mode_setup(mode, root)
    return (((mode == "git") and lint_error_repository_scenario(root)) or lint_error_configured_scenario(root))
  end
  local function lint_error_mode_args(mode)
    return (((mode == "base") and {"lint", "--base", "missing-ref"}) or (((mode == "changed") or (mode == "git")) and {"lint", "--changed"}) or {"lint"})
  end
  local function lint_error_mode_scenario_body(mode, root)
    local _ = lint_error_mode_setup(mode, root)
    local result = bounded_cli(root, lint_error_mode_args(mode))
    local line = (result.lines[1] or "")
    return {code = result.code, line = line, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  local function lint_error_mode_scenario(mode)
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, "p")
    local function _198_()
      return vim.fn.delete(root, "rf")
    end
    local function _199_()
      return lint_error_mode_scenario_body(mode, root)
    end
    return with_cleanup(_198_, _199_)
  end
  local function stale_exclusion_config(mode)
    return ((((mode == "untouched") or (mode == "all")) and "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}") or ((mode == "modified") and "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}") or "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions [{:path \"missing[.]fnl\" :reason \"old intentional branch\"}]}]}}}")
  end
  local function stale_exclusion_setup(root, config_path, a_path, b_path, gone_path, config, mode)
    git_init(root)
    write_file(config_path, lint_config(config))
    write_file(a_path, "(if x (do (foo) (bar)) nil)\n")
    write_file(b_path, "(if y (do (baz) (qux)) nil)\n")
    write_file(gone_path, "(if z (do (old) (code)) nil)\n")
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    return ((((mode == "untouched") or (mode == "all")) and write_file(a_path, "(if changed (do (foo) (bar)) nil)\n")) or ((mode == "modified") and write_file(a_path, "(if changed (do (foo) (bar)) nil)\n")) or git_run(root, {"rm", "-q", "gone.fnl"}))
  end
  local function stale_exclusion_args(mode)
    return (((mode == "all") and {"lint", "--all"}) or {"lint", "--changed"})
  end
  local function stale_exclusion_scenario_body(mode, root, a_path, b_path, gone_path, config_path, config)
    local _ = stale_exclusion_setup(root, config_path, a_path, b_path, gone_path, config, mode)
    local result = bounded_cli(root, stale_exclusion_args(mode))
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  local function stale_exclusion_scenario(mode)
    local root = vim.fn.tempname()
    local a_path = (root .. "/a.fnl")
    local b_path = (root .. "/b.fnl")
    local gone_path = (root .. "/gone.fnl")
    local config_path = (root .. "/.fnl-extras.fnl")
    local config = stale_exclusion_config(mode)
    vim.fn.mkdir(root, "p")
    local function _200_()
      return vim.fn.delete(root, "rf")
    end
    local function _201_()
      return stale_exclusion_scenario_body(mode, root, a_path, b_path, gone_path, config_path, config)
    end
    return with_cleanup(_200_, _201_)
  end
  local function shallow_clone_setup(source, config)
    git_init(source)
    write_file((source .. "/.fnl-extras.fnl"), lint_config(config))
    write_file((source .. "/a.fnl"), "(if x 1 2)\n")
    git_run(source, {"add", "."})
    return git_run(source, {"commit", "-qm", "base"})
  end
  local function shallow_clone_args(mode)
    return (((mode == "all") and {"lint", "--all"}) or {"lint", "--changed"})
  end
  local function shallow_clone_success_result(mode, clone)
    local result = bounded_cli(clone, shallow_clone_args(mode))
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  local function shallow_clone_result(mode, clone, clone_result)
    if (0 ~= clone_result.code) then
      return {code = clone_result.code, lines = clone_result.lines, ["timed-out?"] = clone_result["timed-out?"]}
    else
      return shallow_clone_success_result(mode, clone)
    end
  end
  local function shallow_clone_scenario_body(mode, source, clone, config, clone_command)
    local _ = shallow_clone_setup(source, config)
    local clone_result = bounded_command(clone_command)
    return shallow_clone_result(mode, clone, clone_result)
  end
  local function shallow_clone_scenario(mode)
    local source = vim.fn.tempname()
    local clone = vim.fn.tempname()
    local config = "{:lint {:rules {\"module-style\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}]}}}"
    local clone_command = ("git clone --depth 1 " .. vim.fn.shellescape(("file://" .. source)) .. " " .. vim.fn.shellescape(clone) .. " </dev/null 2>&1")
    vim.fn.mkdir(source, "p")
    local function _203_()
      vim.fn.delete(source, "rf")
      return vim.fn.delete(clone, "rf")
    end
    local function _204_()
      return shallow_clone_scenario_body(mode, source, clone, config, clone_command)
    end
    return with_cleanup(_203_, _204_)
  end
  local function default_lint_setup(root, config, warn, config_text, mode)
    write_file(config, lint_config(config_text))
    write_file(warn, "(if x (do (foo) (bar)) nil)\n")
    if (mode == "git") then
      git_init(root)
      git_run(root, {"add", "."})
      return git_run(root, {"commit", "-qm", "base"})
    else
      return nil
    end
  end
  local function default_lint_result(root)
    local result = bounded_cli(root, {"lint"})
    return {code = result.code, lines = result.lines}
  end
  local function default_lint_scenario(mode)
    local root = vim.fn.tempname()
    local config = (root .. "/.fnl-extras.fnl")
    local warn = (root .. "/warning.fnl")
    local config_text = "{:lint {:rules {\"module-import\" :off \"function-shape\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}] \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"
    vim.fn.mkdir(root, "p")
    local function _206_()
      return vim.fn.delete(root, "rf")
    end
    local function _207_()
      default_lint_setup(root, config, warn, config_text, mode)
      return default_lint_result(root)
    end
    return with_cleanup(_206_, _207_)
  end
  local function default_lint_all_files_setup(root, config, warn, error, config_text)
    git_init(root)
    write_file(config, lint_config(config_text))
    write_file(warn, "(if x (do (foo) (bar)) nil)\n")
    write_file(error, "(testing \"x\" (is 1) (is 2))\n")
    git_run(root, {"add", "."})
    return git_run(root, {"commit", "-qm", "base"})
  end
  local function default_lint_all_files_result(root, config, warn, error, config_text)
    local _ = default_lint_all_files_setup(root, config, warn, error, config_text)
    local result = bounded_cli(root, {"lint"})
    return {code = result.code, lines = result.lines}
  end
  local function default_lint_all_files_scenario()
    local root = vim.fn.tempname()
    local config = (root .. "/.fnl-extras.fnl")
    local warn = (root .. "/warning.fnl")
    local error = (root .. "/error.fnl")
    local config_text = "{:lint {:rules {\"module-import\" :off \"function-shape\" :off :if-branch-call [{:severity :warning :applies-to {:forms [\"if\"]} :options {} :exclusions []}] \"module-style\" :off :form-child-count [{:severity :error :applies-to {:forms [\"testing\"]} :options { :children [\"is\"] :max-count 1} :exclusions []}] \"module-import\" :off \"module-import\" :off \"forbidden-form\" :off}}}"
    vim.fn.mkdir(root, "p")
    local function _208_()
      return vim.fn.delete(root, "rf")
    end
    local function _209_()
      return default_lint_all_files_result(root, config, warn, error, config_text)
    end
    return with_cleanup(_208_, _209_)
  end
  local function _210_()
    local function _211_()
      local result = default_lint_all_files_scenario()
      local text = table.concat(result.lines, "\n")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((1 == result.code) and string.match(text, "warning%.fnl:1:7: warning if%-branch%-call") and string.match(text, "error%.fnl:1:1: error form%-child%-count"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (. result \"code\")) (string.match text \"warning%.fnl:1:7: warning if%-branch%-call\") (string.match text \"error%.fnl:1:1: error form%-child%-count\"))")
      return true
    end
    require("plenary.busted").it("default lint reports findings from all committed files", _211_)
    local function _212_()
      local result = default_lint_scenario("no-git")
      local text = table.concat(result.lines, "\n")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((0 == result.code) and string.match(text, "warning%.fnl:1:7: warning if%-branch%-call") and not string.match(text, "lint requires a Git repository"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (string.match text \"warning%.fnl:1:7: warning if%-branch%-call\") (not (string.match text \"lint requires a Git repository\")))")
      return true
    end
    return require("plenary.busted").it("default lint works without a Git repository", _212_)
  end
  require("plenary.busted").describe("lint-default-selection", _210_)
  local function _213_()
    local function _214_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 0, lines = {}, ["timed-out?"] = false}
      local actual_7_auto = changed_mode_scenario("clean")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("clean repositories produce no changed-mode findings", _214_)
    local function _215_()
      local result = changed_mode_scenario("modified")
      local findings = finding_lines(result.lines)
      local assert_28_auto = require("luassert")
      local value_29_auto = ((0 == result.code) and (1 == #findings) and (2 == #result.lines) and string.match(result.lines[2], "defn:first"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (= 1 (length findings)) (= 2 (length (. result \"lines\"))) (string.match (. result \"lines\" 2) \"defn:first\"))")
      return true
    end
    require("plenary.busted").it("modified files report only the warning whose form intersects changed lines", _215_)
    local function _216_()
      local result = changed_mode_scenario("staged")
      local assert_5_auto = require("luassert")
      local expected_6_auto = 1
      local actual_7_auto = #finding_lines(result.lines)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("staged-only changes are selected", _216_)
    local function _217_()
      local result = changed_mode_scenario("both")
      local assert_5_auto = require("luassert")
      local expected_6_auto = 2
      local actual_7_auto = #finding_lines(result.lines)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("staged and unstaged changes are unioned against HEAD", _217_)
    local function _218_()
      local result = changed_mode_scenario("untracked")
      local assert_5_auto = require("luassert")
      local expected_6_auto = 1
      local actual_7_auto = #finding_lines(result.lines)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("untracked files are selected as whole files", _218_)
    local function _219_()
      local result = changed_mode_scenario("rename")
      local findings = finding_lines(result.lines)
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == #findings) and string.match(result.lines[1], "renamed file%.fnl"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length findings)) (string.match (. result \"lines\" 1) \"renamed file%.fnl\"))")
      return true
    end
    require("plenary.busted").it("renamed destinations are selected as whole files and paths with spaces survive", _219_)
    local function _220_()
      local root_result = changed_mode_scenario("modified")
      local subdir_result = changed_mode_scenario("subdir")
      local root = finding_lines(root_result.lines)
      local subdir = finding_lines(subdir_result.lines)
      local assert_28_auto = require("luassert")
      local value_29_auto = (not root_result["timed-out?"] and not subdir_result["timed-out?"] and (#root == #subdir))
      assert_28_auto.is_truthy(value_29_auto, "(and (not (. root-result \"timed-out?\")) (not (. subdir-result \"timed-out?\")) (= (length root) (length subdir)))")
      return true
    end
    require("plenary.busted").it("subdirectory invocation matches root changed-mode selection without timing out", _220_)
    local function _221_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 1
      local actual_7_auto = file_size_changed_mode_scenario()["changed-file-size"]
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("changed oversized files report exactly one file-size finding", _221_)
    local function _222_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 0
      local actual_7_auto = file_size_changed_mode_scenario()["unchanged-file-size"]
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("unchanged oversized files do not report file-size findings in changed mode", _222_)
  end
  require("plenary.busted").describe("git-changed-selection", _213_)
  local function _223_()
    local function _224_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 1
      local actual_7_auto = #finding_lines(base_mode_scenario().lines)
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("base ref includes committed changes since the selected base", _224_)
    local function _225_()
      local result = lint_error_mode_scenario("git")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == result.code) and string.match(result.line, "lint requires a Git repository"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (. result \"line\") \"lint requires a Git repository\"))")
      return true
    end
    require("plenary.busted").it("changed lint outside a Git repository exits two with the repository message", _225_)
    local function _226_()
      local result = invalid_git_scenario("all")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((0 == result.code) and ("" == result.line))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (= \"\" (. result \"line\")))")
      return true
    end
    require("plenary.busted").it("lint all works in an empty Git directory without resolving Git state", _226_)
    local function _227_()
      local result = invalid_git_scenario("changed")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == result.code) and string.match(result.line, "lint requires a Git repository"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (. result \"line\") \"lint requires a Git repository\"))")
      return true
    end
    require("plenary.busted").it("changed lint rejects an empty Git directory with the repository message", _227_)
    local function _228_()
      local result = lint_error_mode_scenario("base")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == result.code) and string.match(table.concat(result.lines, "\n"), "missing%-ref"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (table.concat (. result \"lines\") \"\\n\") \"missing%-ref\"))")
      return true
    end
    require("plenary.busted").it("an unknown base ref exits two and names the ref", _228_)
    local function _229_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 1, lines = {"a.fnl:1:1: error form-child-count: each testing form must contain exactly one is", "  exclusion: {:rule \"form-child-count\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"}, ["timed-out?"] = false}
      local actual_7_auto = unborn_git_scenario("all")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("all mode lints an unborn repository without resolving HEAD", _229_)
    local function _230_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 2, lines = {"unknown base ref: HEAD"}, ["timed-out?"] = false}
      local actual_7_auto = unborn_git_scenario("changed")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("changed mode reports the unknown unborn HEAD base", _230_)
  end
  require("plenary.busted").describe("git-base-and-errors", _223_)
  local function _231_()
    local function _232_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 0, lines = {}, ["timed-out?"] = false}
      local actual_7_auto = stale_exclusion_scenario("untouched")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("an untouched file's stale exclusion does not fail changed mode", _232_)
    local function _233_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 0, lines = {}, ["timed-out?"] = false}
      local actual_7_auto = stale_exclusion_scenario("modified")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a stale exclusion outside the modified file scope does not fail changed mode", _233_)
    local function _234_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 0, lines = {}, ["timed-out?"] = false}
      local actual_7_auto = stale_exclusion_scenario("deleted")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("a deleted file's exclusion outside the changed scope does not fail changed mode", _234_)
    local function _235_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {code = 1, lines = {".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: missing[.]fnl"}, ["timed-out?"] = false}
      local actual_7_auto = stale_exclusion_scenario("all")
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("all mode reports stale exclusions regardless of file scope", _235_)
  end
  require("plenary.busted").describe("stale-exclusion-scope", _231_)
  local function _236_()
    local function _237_()
      local result = shallow_clone_scenario("changed")
      local line = (result.lines[1] or "")
      local assert_28_auto = require("luassert")
      local value_29_auto = (not result["timed-out?"] and (2 == result.code) and string.match(line, "full clone"))
      assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"timed-out?\")) (= 2 (. result \"code\")) (string.match line \"full clone\"))")
      return true
    end
    require("plenary.busted").it("a shallow clone exits two with the full-clone message", _237_)
    local function _238_()
      local result = shallow_clone_scenario("all")
      local assert_28_auto = require("luassert")
      local value_29_auto = (not result["timed-out?"] and (0 == result.code) and (0 == #result.lines))
      assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"timed-out?\")) (= 0 (. result \"code\")) (= 0 (length (. result \"lines\"))))")
      return true
    end
    return require("plenary.busted").it("all mode lints a shallow clone without requiring a full clone", _238_)
  end
  require("plenary.busted").describe("shallow-clone", _236_)
  local function _239_()
    local function _240_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 0
      local actual_7_auto = default_lint_scenario("no-git").code
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("default all mode does not require a Git repository", _240_)
  end
  require("plenary.busted").describe("lint-all-git-boundary", _239_)
  local function _241_()
    local function _242_()
      local result = align_bindings_cli_scenario()
      local assert_28_auto = require("luassert")
      local value_29_auto = ((1 == result["check-code"]) and vim.deep_equal({"a.fnl"}, result["check-lines"]) and (0 == result["write-code"]) and vim.deep_equal({"a.fnl"}, result["write-lines"]) and (result.expected == result.content))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (. result \"check-code\")) (vim.deep_equal [\"a.fnl\"] (. result \"check-lines\")) (= 0 (. result \"write-code\")) (vim.deep_equal [\"a.fnl\"] (. result \"write-lines\")) (= (. result \"expected\") (. result \"content\")))")
      return true
    end
    return require("plenary.busted").it("check reports missing binding alignment and write fixes it", _242_)
  end
  require("plenary.busted").describe("align-bindings-cli", _241_)
  local function alignment_maps_cli_setup(config_path, path, source)
    write_file(config_path, "{:indent-width 2 :builtins {\"fn\" [[:inner 0]] \"lambda\" [[:inner 0]] \"macro\" [[:inner 0]] \"let\" [[:block 1]] \"when\" [[:block 1]] \"when-let\" [[:block 1]] \"if-let\" [[:block 1]] \"each\" [[:block 1]] \"for\" [[:block 1]] \"icollect\" [[:block 1]] \"collect\" [[:block 1]] \"accumulate\" [[:block 1]] \"case\" [[:block 1]] \"match\" [[:block 1]] \"case-try\" [[:block 1]] \"match-try\" [[:block 1]] \"while\" [[:block 1]] \"with-open\" [[:block 1]] \"do\" [[:block 0]]} :prefix-fallbacks {\"def\" [[:inner 0]] \"with-\" [[:block 1]]} :parser false :alignment {:bindings false :maps true :clauses false :split-bindings false :collapse-padding false :binding-forms [\"let\" \"when-let\" \"if-let\" \"with-open\"] :clause-forms [\"case\" \"match\" \"case-try\" \"match-try\" \"if\"]}}")
    return write_file(path, source)
  end
  local function alignment_maps_cli_scenario_body(root, config_path, path, source, expected)
    local _ = alignment_maps_cli_setup(config_path, path, source)
    local check_result = run_cli(root, {"format", "--check", "a.fnl"})
    local write_result = run_cli(root, {"format", "--write", "a.fnl"})
    local result = {["check-code"] = check_result.code, ["check-lines"] = check_result.lines, ["write-code"] = write_result.code, ["write-lines"] = write_result.lines, content = read_file(path), expected = expected}
    vim.fn.delete(root, "rf")
    return result
  end
  local function alignment_maps_cli_scenario()
    local root = vim.fn.tempname()
    local path = (root .. "/a.fnl")
    local config_path = (root .. "/.fnl-extras.fnl")
    local source = "{:a 1\n :long 2}"
    local expected = "{:a    1\n :long 2}"
    vim.fn.mkdir(root, "p")
    vim.fn.mkdir((root .. "/.git"), "p")
    return alignment_maps_cli_scenario_body(root, config_path, path, source, expected)
  end
  local function _243_()
    local function _244_()
      local result = alignment_maps_cli_scenario()
      local assert_28_auto = require("luassert")
      local value_29_auto = ((1 == result["check-code"]) and vim.deep_equal({"a.fnl"}, result["check-lines"]) and (0 == result["write-code"]) and vim.deep_equal({"a.fnl"}, result["write-lines"]) and (result.expected == result.content))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (. result \"check-code\")) (vim.deep_equal [\"a.fnl\"] (. result \"check-lines\")) (= 0 (. result \"write-code\")) (vim.deep_equal [\"a.fnl\"] (. result \"write-lines\")) (= (. result \"expected\") (. result \"content\")))")
      return true
    end
    return require("plenary.busted").it("check reports missing map alignment and write fixes it from alignment config", _244_)
  end
  require("plenary.busted").describe("alignment-maps-cli", _243_)
  local function _245_()
    local function _246_()
      local result = lint_project("{:lint {:rules {:if-without-else [{:severity :warning :applies-to {:forms [\"if\"]} :options {:nil-else true} :exclusions []}]}}}", {["a.fnl"] = "(if ok then)\n(var x 1)\n"}, {"lint", "--all"})
      local assert_28_auto = require("luassert")
      local value_29_auto = ((0 == result.code) and (2 == #result.lines) and string.match(result.lines[1], "if%-without%-else"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (= 2 (length (. result \"lines\"))) (string.match (. result \"lines\" 1) \"if%-without%-else\"))")
      return true
    end
    require("plenary.busted").it("listing one rule disables unlisted findings", _246_)
    local function _247_()
      local result = lint_project("{:lint {:rules {:file-size [{:severity :warning :applies-to {:files [\"^a[.]fnl$\"]} :options { :max-code-lines 3} :exclusions []}] \"module-style\" :off}}}", {["a.fnl"] = "(module a)\n(local a 1)\n(local b 2)\n(local c 3)\n(local d 4)\n"}, {"lint", "--all"})
      local assert_28_auto = require("luassert")
      local value_29_auto = ((0 == result.code) and (2 == #result.lines) and string.match(result.lines[1], "file%-size") and string.match(result.lines[2], "exclusion:"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (= 2 (length (. result \"lines\"))) (string.match (. result \"lines\" 1) \"file%-size\") (string.match (. result \"lines\" 2) \"exclusion:\"))")
      return true
    end
    return require("plenary.busted").it("file-size uses the nested max-code-lines option", _247_)
  end
  require("plenary.busted").describe("lint-policy-cli-regressions", _245_)
  local function missing_config_cli_scenario_body(root, path, command)
    local _ = write_file(path, "(module a)\n")
    local result = run_cli(root, {command, "--check", "a.fnl"})
    local output = {code = result.code, lines = result.lines}
    vim.fn.delete(root, "rf")
    return output
  end
  local function missing_config_cli_scenario(command)
    local root = vim.fn.tempname()
    local path = (root .. "/a.fnl")
    vim.fn.mkdir(root, "p")
    vim.fn.mkdir((root .. "/.git"), "p")
    return missing_config_cli_scenario_body(root, path, command)
  end
  local function _248_()
    local function _249_()
      local result = missing_config_cli_scenario("format")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == result.code) and string.match((result.lines[1] or ""), "missing .fnl%-extras%.fnl"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"missing .fnl%-extras%.fnl\"))")
      return true
    end
    require("plenary.busted").it("format exits 2 with a clear missing config message", _249_)
    local function _250_()
      local result = missing_config_cli_scenario("lint")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == result.code) and string.match((result.lines[1] or ""), "missing .fnl%-extras%.fnl"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"missing .fnl%-extras%.fnl\"))")
      return true
    end
    return require("plenary.busted").it("lint exits 2 with a clear missing config message", _250_)
  end
  return require("plenary.busted").describe("strict-cli-errors", _248_)
end
return require("plenary.busted").describe("lint-grammar", _131_)
