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
local function run_cli(root, args)
  local lines = {}
  local cli = load_cli()
  if cli["module-missing"] then
    return cli
  else
    local function _3_(line)
      return table.insert(lines, line)
    end
    return {code = cli.run(args, {cwd = root, print = _3_}), lines = lines}
  end
end
local function check_scenario(source, expected_code, expected_lines)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _5_()
    return vim.fn.delete(root, "rf")
  end
  local function _6_()
    write_file(path, source)
    local result = run_cli(root, {"format", "--check", "a.fnl"})
    return {code = result.code, lines = result.lines, content = read_file(path), ["expected-code"] = expected_code, ["expected-lines"] = expected_lines}
  end
  return with_cleanup(_5_, _6_)
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
local function write_scenario(mode)
  local root = vim.fn.tempname()
  local good = (root .. "/good.fnl")
  local bad = (root .. "/bad.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _7_()
    return vim.fn.delete(root, "rf")
  end
  local function _8_()
    if (mode == "good") then
      return write_good_scenario(root, good)
    else
      if (mode == "formatted") then
        return write_formatted_scenario(root, good)
      else
        return write_error_scenario(root, good, bad)
      end
    end
  end
  return with_cleanup(_7_, _8_)
end
local function config_indent_scenario(root, src_file, config_path)
  local _ = write_file(config_path, "{:indents {\"deftest\" [[:block 1]]}}")
  local _0 = write_file(src_file, "(deftest t\n(foo))\n")
  local result = run_cli(root, {"format", "--write", "src/a.fnl"})
  return {code = result.code, lines = result.lines, content = read_file(src_file)}
end
local function config_exclude_scenario(root, src_file, skip_file, config_path)
  local _ = write_file(config_path, "{:exclude [\"skip\"]}\n")
  local _0 = write_file(src_file, "(when x\n  y)\n")
  local _1 = write_file(skip_file, "(when x\ny)\n")
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, lines = result.lines, content = read_file(skip_file)}
end
local function config_paths_scenario(root, src_file, skip_file, config_path)
  local _ = write_file(config_path, "{:paths [\"src\"]}")
  local _0 = write_file(src_file, "(when x\ny)\n")
  local _1 = write_file(skip_file, "(when x\ny)\n")
  local result = run_cli(root, {"format", "--write"})
  return {code = result.code, lines = result.lines, src = read_file(src_file), skip = read_file(skip_file)}
end
local function config_invalid_scenario(root, src_file, config_path)
  local _ = write_file(config_path, "{:colour 1}")
  local result = run_cli(root, {"format", "--check", "src/a.fnl"})
  return {code = result.code, lines = result.lines}
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
  local function _11_()
    return vim.fn.delete(root, "rf")
  end
  local function _12_()
    if (mode == "indent") then
      return config_indent_scenario(root, src_file, config_path)
    else
      if (mode == "exclude") then
        return config_exclude_scenario(root, src_file, skip_file, config_path)
      else
        if (mode == "paths") then
          return config_paths_scenario(root, src_file, skip_file, config_path)
        else
          return config_invalid_scenario(root, src_file, config_path)
        end
      end
    end
  end
  return with_cleanup(_11_, _12_)
end
local function align_bindings_cli_scenario()
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  local source = "(let [a 1\n      long-name 2]\n  a)"
  local expected = "(let [a         1\n      long-name 2]\n  a)"
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _16_()
    return vim.fn.delete(root, "rf")
  end
  local function _17_()
    write_file(config_path, "{:align-bindings true}")
    write_file(path, source)
    local check_result = run_cli(root, {"format", "--check", "a.fnl"})
    local write_result = run_cli(root, {"format", "--write", "a.fnl"})
    return {["check-code"] = check_result.code, ["check-lines"] = check_result.lines, ["write-code"] = write_result.code, ["write-lines"] = write_result.lines, content = read_file(path), expected = expected}
  end
  return with_cleanup(_16_, _17_)
end
local function _18_()
  local function _19_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, content = "(when x\n  y)\n", ["expected-code"] = 0, ["expected-lines"] = {}}
    local actual_7_auto = check_scenario("(when x\n  y)\n", 0, {})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns zero and no lines for an already-formatted project", _19_)
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, content = "(when x\ny)\n", ["expected-code"] = 1, ["expected-lines"] = {"a.fnl"}}
    local actual_7_auto = check_scenario("(when x\ny)\n", 1, {"a.fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns one and leaves an unformatted file unchanged", _20_)
end
require("plenary.busted").describe("check", _18_)
local function _21_()
  local function _22_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"good.fnl"}, good = "(when x\n  y)\n"}
    local actual_7_auto = write_scenario("good")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rewrites an unformatted file and reports its relative path", _22_)
  local function _23_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, good = "(when x\n  y)\n", ["entry-count"] = 1}
    local actual_7_auto = write_scenario("formatted")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not rewrite an already-formatted file or leave a temp file", _23_)
  local function _24_()
    local result = write_scenario("error")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and ("(when x\ny)\n" == result.good) and ("(x" == result.bad) and (1 == #result.lines) and string.match(result.lines[1], "^bad%.fnl:[0-9]+:[0-9]+: .*"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (= \"(when x\ny)\n\" (. result \"good\")) (= \"(x\" (. result \"bad\")) (= 1 (length (. result \"lines\"))) (string.match (. result \"lines\" 1) \"^bad%.fnl:[0-9]+:[0-9]+: .*\"))")
    return true
  end
  return require("plenary.busted").it("formats all files before writing and leaves the good file unchanged on error", _24_)
end
require("plenary.busted").describe("write", _21_)
local function _25_()
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"src/a.fnl"}, content = "(deftest t\n  (foo))\n"}
    local actual_7_auto = config_scenario("indent")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured indentation rules", _26_)
  local function _27_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, content = "(when x\ny)\n"}
    local actual_7_auto = config_scenario("exclude")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("skips files under configured exclude prefixes", _27_)
  local function _28_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"src/a.fnl"}, src = "(when x\n  y)\n", skip = "(when x\ny)\n"}
    local actual_7_auto = config_scenario("paths")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured paths for a no-argument run", _28_)
  local function _29_()
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
  return require("plenary.busted").it("returns one config error line for an invalid configuration", _29_)
end
require("plenary.busted").describe("config", _25_)
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
local function extension_scenario(extension)
  local root = vim.fn.tempname()
  local path = (root .. "/source" .. extension)
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _30_()
    return vim.fn.delete(root, "rf")
  end
  local function _31_()
    write_file(config_path, ("{:extensions [\"" .. extension .. "\"]}"))
    if (extension == ".fnl") then
      return extension_fnl_scenario(root, path, config_path)
    else
      return extension_other_scenario(root, path, config_path)
    end
  end
  return with_cleanup(_30_, _31_)
end
local function default_path_scenario()
  local root = vim.fn.tempname()
  local path = (root .. "/source.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _33_()
    return vim.fn.delete(root, "rf")
  end
  local function _34_()
    write_file(path, "(when x\ny)\n")
    local result = run_cli(root, {"format", "--write"})
    return {code = result.code, lines = result.lines, content = read_file(path)}
  end
  return with_cleanup(_33_, _34_)
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
  local function _35_()
    return vim.fn.delete(root, "rf")
  end
  local function _36_()
    write_file((root .. "/.fnl-extras.fnl"), "{:paths [\"fnl\"] :skip-dotfiles false}")
    write_file(hidden_file, "(when x\ny)\n")
    write_file(nested_file, "(when x\ny)\n")
    write_file(git_file, "(when x\ny)\n")
    local result = run_cli(root, {"format", "--check"})
    return {code = result.code, lines = result.lines, hidden = vim.loop.fs_stat(hidden_file).type, nested = vim.loop.fs_stat(nested_file).type, git = read_file(git_file)}
  end
  return with_cleanup(_35_, _36_)
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
  local function _37_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _38_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result = run_cli(root, {"format", "--write"})
    return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
  end
  return with_cleanup(_37_, _38_)
end
local function follow_directory_symlink_scenario(mode)
  local root = vim.fn.tempname()
  local outside = vim.fn.tempname()
  local link = (root .. "/linkdir")
  local target = (outside .. "/a.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir(outside, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _39_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _40_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(outside, link))
    local result
    local function _41_()
      if (mode == "check") then
        return {"format", "--check"}
      else
        return {"format", "--write"}
      end
    end
    result = run_cli(root, _41_())
    if (mode == "check") then
      return {code = result.code, lines = result.lines, target = read_file(target)}
    else
      return {code = result.code, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
    end
  end
  return with_cleanup(_39_, _40_)
end
local function parser_scenario(mode)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _43_()
    return vim.fn.delete(root, "rf")
  end
  local function _44_()
    write_file(path, "(when x\ny)\n")
    write_file(config_path, "{:parser \"missing.parser.module\"}")
    local result
    local function _45_()
      if (mode == "config") then
        return {"format", "--check", "a.fnl"}
      else
        return {"format", "--check", "--parser", "eca.nfnl.fennel", "a.fnl"}
      end
    end
    result = run_cli(root, _45_())
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_43_, _44_)
end
local function rule_config_scenario(config, source, expected)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _46_()
    return vim.fn.delete(root, "rf")
  end
  local function _47_()
    write_file(config_path, config)
    write_file(path, source)
    local result = run_cli(root, {"format", "--write", "a.fnl"})
    return {code = result.code, lines = result.lines, content = read_file(path), expected = expected}
  end
  return with_cleanup(_46_, _47_)
end
local function config_discovery_scenario(mode)
  local root = vim.fn.tempname()
  local config_path = (root .. "/.fnl-extras.fnl")
  local source_path = (root .. "/a.fnl")
  local config = "{:skip-dotfiles false\n:paths [\".\"]}\n"
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _48_()
    return vim.fn.delete(root, "rf")
  end
  local function _49_()
    write_file(config_path, config)
    write_file(source_path, "(when x\ny)\n")
    local result
    local function _50_()
      if (mode == "check") then
        return {"format", "--check"}
      else
        return {"format", "--write"}
      end
    end
    result = run_cli(root, _50_())
    return {code = result.code, lines = result.lines, config = read_file(config_path), source = read_file(source_path)}
  end
  return with_cleanup(_48_, _49_)
end
local function _51_()
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"source.fnl"}}
    local actual_7_auto = extension_scenario(".fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses only configured extensions during discovery", _52_)
  local function _53_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"source.fnlx"}}
    local actual_7_auto = extension_scenario(".fnlx")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("discovers a configured non-default extension", _53_)
  local function _54_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"source.fnl"}, content = "(when x\n  y)\n"}
    local actual_7_auto = default_path_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("walks the current directory when paths are absent from config and CLI", _54_)
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"fnl/.hidden.fnl", "fnl/.hidden/nested.fnl"}, hidden = "file", nested = "file", git = "(when x\ny)\n"}
    local actual_7_auto = dotfiles_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formats dotfiles and dot-directories when skip-dotfiles is false but never .git", _55_)
  local function _56_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"fnl/link.fnl"}, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_symlink_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("follows file symlinks to real targets and preserves the symlink", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"linkdir/a.fnl"}, target = "(when x\ny)\n"}
    local actual_7_auto = follow_directory_symlink_scenario("check")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports files under followed directory symlinks by logical path", _57_)
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_directory_symlink_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("writes files under followed directory symlinks to their real targets", _58_)
  local function _59_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"could not require parser module: missing.parser.module"}}
    local actual_7_auto = parser_scenario("config")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the parser named by config when no CLI parser is given", _59_)
  local function _60_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}}
    local actual_7_auto = parser_scenario("flag")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("CLI parser overrides the parser named by config", _60_)
end
require("plenary.busted").describe("new-configuration", _51_)
local function symlink_loop_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local file = (fnl_dir .. "/a.fnl")
  local loop_path = (fnl_dir .. "/loop")
  local script = (vim.fn.getcwd() .. "/scripts/fennel-extras")
  vim.fn.mkdir(fnl_dir, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _61_()
    return vim.fn.delete(root, "rf")
  end
  local function _62_()
    write_file(file, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(root, loop_path))
    local command = ("cd " .. vim.fn.shellescape(root) .. " && perl -e 'alarm shift; exec @ARGV' 10 " .. vim.fn.shellescape(script) .. " format --check")
    local lines = vim.fn.systemlist({"sh", "-c", command})
    return {code = vim.v.shell_error, lines = lines}
  end
  return with_cleanup(_61_, _62_)
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
local function two_phase_write_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local read_only = (fnl_dir .. "/ro")
  local good = (fnl_dir .. "/a.fnl")
  local blocked = (read_only .. "/b.fnl")
  local probe = (read_only .. "/probe")
  vim.fn.mkdir(read_only, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _63_()
    vim.fn.setfperm(read_only, "rwxr-xr-x")
    return vim.fn.delete(root, "rf")
  end
  local function _64_()
    write_file(good, "(when x\ny)\n")
    write_file(blocked, "(when y\nz)\n")
    vim.fn.setfperm(read_only, "r-xr-xr-x")
    local probe_file = io.open(probe, "w")
    if probe_file then
      return two_phase_skipped_scenario(probe_file, probe)
    else
      return two_phase_write_attempt(root, good)
    end
  end
  return with_cleanup(_63_, _64_)
end
local function dotfile_config_scenario(root, fnl_dir)
  local _ = write_file((root .. "/.fnl-extras.fnl"), "{}\n")
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
  local function _66_()
    return vim.fn.delete(root, "rf")
  end
  local function _67_()
    if (mode == "config") then
      return dotfile_config_scenario(root, fnl_dir)
    else
      return dotfile_source_scenario(root)
    end
  end
  return with_cleanup(_66_, _67_)
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
  local function _69_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _70_()
    write_file(good, "(when x\n  y)\n")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result
    local function _71_()
      if (mode == "write") then
        return {"format", "--write"}
      else
        return {"format", "--check", "fnl/link.fnl"}
      end
    end
    result = run_cli(root, _71_())
    return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
  end
  return with_cleanup(_69_, _70_)
end
local function follow_symlink_dedupe_scenario()
  local root = vim.fn.tempname()
  local target = (root .. "/a.fnl")
  local link = (root .. "/b.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _72_()
    return vim.fn.delete(root, "rf")
  end
  local function _73_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result = run_cli(root, {"format", "--write"})
    return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
  end
  return with_cleanup(_72_, _73_)
end
local function follow_symlink_cycle_scenario()
  local root = vim.fn.tempname()
  local directory = (root .. "/d")
  local file = (directory .. "/x.fnl")
  local loop_path = (directory .. "/loop")
  vim.fn.mkdir(directory, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _74_()
    return vim.fn.delete(root, "rf")
  end
  local function _75_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(file, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(root, loop_path))
    local result = run_cli(root, {"format", "--check"})
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_74_, _75_)
end
local function follow_symlink_explicit_scenario()
  local root = vim.fn.tempname()
  local target = (root .. "/real.fnl")
  local link = (root .. "/link.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _76_()
    return vim.fn.delete(root, "rf")
  end
  local function _77_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result = run_cli(root, {"format", "--check", "link.fnl"})
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_76_, _77_)
end
local function unreadable_directory_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local locked = (fnl_dir .. "/locked")
  local good = (fnl_dir .. "/a.fnl")
  vim.fn.mkdir(locked, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _78_()
    vim.fn.setfperm(locked, "rwxr-xr-x")
    return vim.fn.delete(root, "rf")
  end
  local function _79_()
    write_file(good, "(when x\n  y)\n")
    vim.fn.setfperm(locked, "---------")
    local handle = vim.loop.fs_scandir(locked)
    if handle then
      return {["skipped-root"] = true}
    else
      local result = run_cli(root, {"format", "--check"})
      local lines = result.lines
      return {code = result.code, ["mentions-read-error"] = not not string.match((lines[1] or ""), "cannot read directory")}
    end
  end
  return with_cleanup(_78_, _79_)
end
local function _81_()
  local function _82_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(when x\n    y)\n", expected = "(when x\n    y)\n"}
    local actual_7_auto = rule_config_scenario("{:indent-width 4}", "(when x\ny)\n", "(when x\n    y)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured indent-width", _82_)
  local function _83_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(let [x 1]\n     x)\n", expected = "(let [x 1]\n     x)\n"}
    local actual_7_auto = rule_config_scenario("{:builtins false}", "(let [x 1]\nx)\n", "(let [x 1]\n     x)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("disables built-in indentation rules when builtins is false", _83_)
  local function _84_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(defn x\n      y)\n", expected = "(defn x\n      y)\n"}
    local actual_7_auto = rule_config_scenario("{:prefix-fallbacks false}", "(defn x\ny)\n", "(defn x\n      y)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("disables prefix fallback indentation rules when prefix-fallbacks is false", _84_)
end
require("plenary.busted").describe("configured-formatting-rules", _81_)
local function _85_()
  local function _86_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, config = "{:skip-dotfiles false\n:paths [\".\"]}\n", source = "(when x\ny)\n"}
    local actual_7_auto = config_discovery_scenario("check")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report the discovered config file as a formatting target", _86_)
  local function _87_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, config = "{:skip-dotfiles false\n:paths [\".\"]}\n", source = "(when x\n  y)\n"}
    local actual_7_auto = config_discovery_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not rewrite the discovered config file", _87_)
end
require("plenary.busted").describe("config-file-discovery", _85_)
local function _88_()
  local function _89_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"fnl/a.fnl"}}
    local actual_7_auto = symlink_loop_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not recurse through directory symlinks", _89_)
  local function _90_()
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
  require("plenary.busted").it("does not partially write files when a later write fails", _90_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}}
    local actual_7_auto = dotfile_scenario("config")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not discover a dotfile config as source", _92_)
  local function _93_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"no files found"}}
    local actual_7_auto = dotfile_scenario("source")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not discover a dotfile with a Fennel extension", _93_)
  local function _94_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, ["link-type"] = "link", target = "(when x\ny)\n"}
    local actual_7_auto = symlink_file_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("skips symlinked files during no-argument writes", _94_)
  local function _95_()
    local result = symlink_file_scenario("check")
    local lines = result.lines
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, ["line-count"] = 1, ["mentions-symlink"] = true}
    local actual_7_auto = {code = result.code, ["line-count"] = #lines, ["mentions-symlink"] = not not string.match((lines[1] or ""), "symlink")}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an explicit symlink file argument", _95_)
  local function _96_()
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
  require("plenary.busted").it("reports an unreadable directory", _96_)
  local function _98_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_symlink_dedupe_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("processes a real file only once when a symlink points to it", _98_)
  local function _99_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"d/x.fnl"}}
    local actual_7_auto = follow_symlink_cycle_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("terminates when a followed directory symlink forms a cycle", _99_)
  local function _100_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"link.fnl"}}
    local actual_7_auto = follow_symlink_explicit_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("follows an explicitly named symlink file", _100_)
end
require("plenary.busted").describe("edge-cases", _88_)
local function lint_git_command(root, args)
  local escaped_args
  local _101_
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
    _101_ = tbl_26_
  end
  escaped_args = table.concat(_101_, " ")
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
local function lint_project(config, files, args)
  local root = vim.fn.tempname()
  local config_path = (root .. "/.fnl-extras.fnl")
  local before = {}
  local after = {}
  vim.fn.mkdir(root, "p")
  local function _103_()
    return vim.fn.delete(root, "rf")
  end
  local function _104_()
    lint_git_init(root)
    write_file(config_path, config)
    for path, text in pairs(files) do
      local full = (root .. "/" .. path)
      vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
      write_file(full, text)
      before[path] = read_file(full)
    end
    local result = run_cli(root, args)
    for path, _ in pairs(files) do
      after[path] = read_file((root .. "/" .. path))
    end
    return {code = result.code, lines = result.lines, before = before, after = after}
  end
  return with_cleanup(_103_, _104_)
end
local function lint_grammar_scenario(args)
  return lint_project("{:lint {:rules {\"module-style\" :off}}}", {["a.fnl"] = "(if x 1 2)\n"}, args)
end
local function lint_discovery_scenario(mode)
  local config = "{:paths [\"src\"] :exclude [\"src/skip\"] :extensions [\".fnl\"] :lint {:rules {\"module-style\" :off}}}"
  local files = {["src/keep.fnl"] = "(if x 1 2)\n", ["src/skip/no.fnl"] = "(if x 1 2)\n", ["other.fnl"] = "(if x 1 2)\n"}
  local function _105_()
    if (mode == "default") then
      return {"lint", "--all"}
    else
      return {"lint", "--all", "src/keep.fnl"}
    end
  end
  return lint_project(config, files, _105_())
end
local function lint_output_scenario(mode)
  local config
  if (mode == "error") then
    config = "{:lint {:rules {\"module-style\" :off}}}"
  else
    if (mode == "warning-error") then
      config = "{:lint {:rules {\"module-style\" :off \"if-branch-call\" :error}}}"
    else
      if (mode == "off") then
        config = "{:lint {:rules {\"module-style\" :off \"if-branch-call\" :off}}}"
      else
        config = "{:lint {:rules {\"module-style\" :off}}}"
      end
    end
  end
  local source
  if (mode == "error") then
    source = "(testing \"x\" (is 1) (is 2))\n"
  else
    source = "(if x (do (foo) (bar)) nil)\n"
  end
  return lint_project(config, {["a.fnl"] = source}, {"lint", "--all"})
end
local function lint_exclusion_scenario(mode)
  local config
  if (mode == "stale") then
    config = "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"a.fnl > missing\" :reason \"old intentional branch\"}]}}"
  else
    config = "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"a.fnl > top#1 > if#1 > then\" :reason \"intentional multi-step branch\"}]}}"
  end
  return lint_project(config, {["a.fnl"] = "(if x (do (foo) (bar)) nil)\n"}, {"lint", "--all"})
end
local function lint_error_scenario(mode)
  local config
  if (mode == "config") then
    config = "{:lint {:rules {\"not-a-rule\" :error}}}"
  else
    config = "{:lint {:rules {\"module-style\" :off}}}"
  end
  local source
  if (mode == "config") then
    source = "(if x 1 2)\n"
  else
    source = "(if x"
  end
  return lint_project(config, {["a.fnl"] = source}, {"lint", "--all"})
end
local function _113_()
  local function _114_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = lint_grammar_scenario({"lint", "--all"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts lint all with text output", _114_)
  local function _115_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = lint_grammar_scenario({"lint", "--all", "--format", "json"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("accepts lint all with json output", _115_)
  local function _116_()
    local result = lint_grammar_scenario({"lint", "--all", "--base", "HEAD"})
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and string.match((result.lines[1] or ""), "base"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"base\"))")
    return true
  end
  require("plenary.busted").it("rejects base together with all with exit two and a clear message", _116_)
  local function _117_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--changed", "--all"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects changed together with all with exit two", _117_)
  local function _118_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--wat"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects unknown flags with exit two", _118_)
  local function _119_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--all", "--all"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects duplicate flags with exit two", _119_)
  local function _120_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--format"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects a missing format value with exit two", _120_)
  local function _121_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--format", "yaml"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an invalid format value with exit two", _121_)
  local function _122_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = lint_grammar_scenario({"lint", "--write"}).code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects formatter-only flags for lint", _122_)
  local function _123_()
    local function _124_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = lint_discovery_scenario("default").lines
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("uses configured paths exclusions extensions and omits its config file", _124_)
    local function _125_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {}
      local actual_7_auto = lint_discovery_scenario("explicit").lines
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("optional path arguments restrict lint all discovery", _125_)
  end
  require("plenary.busted").describe("lint-discovery", _123_)
  local function _126_()
    local function _127_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 1
      local actual_7_auto = lint_output_scenario("error").code
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("reports one error finding with text output and exit one", _127_)
    local function _128_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = {"a.fnl:1:1: error one-is-per-testing: each testing form must contain exactly one is", "  exclusion: {:rule \"one-is-per-testing\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"}
      local actual_7_auto = lint_output_scenario("error").lines
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("prints the exact text line and exclusion suggestion for an error", _128_)
    local function _129_()
      local result = lint_output_scenario("warning")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((0 == result.code) and (nil ~= result.lines[1]))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (not= nil (. result \"lines\" 1)))")
      return true
    end
    require("plenary.busted").it("prints a warning but exits zero", _129_)
    local function _130_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 1
      local actual_7_auto = lint_output_scenario("warning-error").code
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("turns the warning into an error when configured", _130_)
    local function _131_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 0
      local actual_7_auto = lint_output_scenario("off").code
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("turns the warning off when configured", _131_)
    local function _132_()
      local result = lint_project("{:lint {:rules {\"module-style\" :off}}}", {["a.fnl"] = "(if x (do (foo) (bar)) nil)\n"}, {"lint", "--all", "--format", "json"})
      local assert_28_auto = require("luassert")
      local value_29_auto = ((0 == result.code) and string.match((result.lines[1] or ""), "^%{"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"^%{\"))")
      return true
    end
    return require("plenary.busted").it("emits json lines with the same warning status", _132_)
  end
  require("plenary.busted").describe("lint-output", _126_)
  local function _133_()
    local function _134_()
      local assert_5_auto = require("luassert")
      local expected_6_auto = 0
      local actual_7_auto = lint_exclusion_scenario("matching").code
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    require("plenary.busted").it("suppresses a matching exclusion in all mode", _134_)
    local function _135_()
      local result = lint_exclusion_scenario("stale")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((1 == result.code) and string.match((result.lines[1] or ""), "^%.fnl%-extras%.fnl:1:1: error if%-branch%-call: stale exclusion: a%.fnl > missing$"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"^%.fnl%-extras%.fnl:1:1: error if%-branch%-call: stale exclusion: a%.fnl > missing$\"))")
      return true
    end
    return require("plenary.busted").it("reports an unmatched exclusion as a stale error in all mode", _135_)
  end
  require("plenary.busted").describe("lint-exclusions", _133_)
  local function _136_()
    local function _137_()
      local result = lint_error_scenario("config")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == result.code) and string.match((result.lines[1] or ""), "not%-a%-rule"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"not%-a%-rule\"))")
      return true
    end
    require("plenary.busted").it("returns exit two with a malformed lint configuration error", _137_)
    local function _138_()
      local result = lint_error_scenario("source")
      local assert_28_auto = require("luassert")
      local value_29_auto = ((2 == result.code) and string.match((result.lines[1] or ""), "a%.fnl:[0-9]+:[0-9]+:"))
      assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (or (. result \"lines\" 1) \"\") \"a%.fnl:[0-9]+:[0-9]+:\"))")
      return true
    end
    require("plenary.busted").it("returns exit two with a source parse diagnostic", _138_)
    local function _139_()
      local result = lint_output_scenario("warning")
      local assert_5_auto = require("luassert")
      local expected_6_auto = result.before
      local actual_7_auto = result.after
      assert_5_auto.same(expected_6_auto, actual_7_auto)
      return true
    end
    return require("plenary.busted").it("does not change any file in all mode", _139_)
  end
  return require("plenary.busted").describe("lint-errors-and-read-only", _136_)
end
require("plenary.busted").describe("lint-grammar", _113_)
local function shell_args(args)
  local _140_
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
    _140_ = tbl_26_
  end
  return table.concat(_140_, " ")
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
local function real_lint_output_scenario(format)
  local root = vim.fn.tempname()
  local config = (root .. "/.fnl-extras.fnl")
  local first_file = (root .. "/a.fnl")
  local second_file = (root .. "/b.fnl")
  local config_text = "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :off \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
  local first_source = "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
  local second_source = "(testing \"c\" (is 1) (is 2))\\n"
  vim.fn.mkdir(root, "p")
  local function _144_()
    return vim.fn.delete(root, "rf")
  end
  local function _145_()
    lint_git_init(root)
    write_file(config, config_text)
    write_file(first_file, first_source)
    write_file(second_file, second_source)
    lint_git_commit(root)
    local result = real_cli_lines(root, {"lint", "--all", "--format", format})
    local lines = result.lines
    return {lines = #lines, objects = 3, ["each-line-one-object?"] = one_json_object_per_line_3f(lines)}
  end
  return with_cleanup(_144_, _145_)
end
local function real_text_lint_output_scenario()
  local root = vim.fn.tempname()
  local config = (root .. "/.fnl-extras.fnl")
  local first_file = (root .. "/a.fnl")
  local second_file = (root .. "/b.fnl")
  local config_text = "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :off \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
  local first_source = "(testing \"a\" (is 1) (is 2))\\n(testing \"b\" (is 1) (is 2))\\n"
  local second_source = "(testing \"c\" (is 1) (is 2))\\n"
  vim.fn.mkdir(root, "p")
  local function _146_()
    return vim.fn.delete(root, "rf")
  end
  local function _147_()
    lint_git_init(root)
    write_file(config, config_text)
    write_file(first_file, first_source)
    write_file(second_file, second_source)
    lint_git_commit(root)
    local result = real_cli_lines(root, {"lint", "--all"})
    return {lines = #result.lines, objects = 3}
  end
  return with_cleanup(_146_, _147_)
end
local function _148_()
  local function _149_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lines = 3, objects = 3, ["each-line-one-object?"] = true}
    local actual_7_auto = real_lint_output_scenario("json")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("prints one JSON object per physical line", _149_)
  local function _150_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {lines = 6, objects = 3}
    local actual_7_auto = real_text_lint_output_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("prints each text finding and exclusion suggestion on its own line", _150_)
end
require("plenary.busted").describe("default-printer", _148_)
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
local function invalid_git_scenario(mode)
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _151_()
    return vim.fn.delete(root, "rf")
  end
  local function _152_()
    write_file((root .. "/.fnl-extras.fnl"), "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}")
    write_file((root .. "/a.fnl"), "(if x 1 2)\\n")
    local result
    local function _153_()
      if (mode == "all") then
        return {"lint", "--all"}
      else
        return {"lint", "--changed"}
      end
    end
    result = bounded_cli(root, _153_())
    local line = (result.lines[1] or "")
    return {code = result.code, line = line, ["timed-out?"] = result["timed-out?"]}
  end
  return with_cleanup(_151_, _152_)
end
local function unborn_git_scenario(mode)
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  local function _154_()
    return vim.fn.delete(root, "rf")
  end
  local function _155_()
    git_init(root)
    write_file((root .. "/.fnl-extras.fnl"), "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :off \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}")
    write_file((root .. "/a.fnl"), "(testing \"x\") (import-macros {: testing : is} :spec.eca.macros)\n")
    local result
    local function _156_()
      if (mode == "all") then
        return {"lint", "--all"}
      else
        return {"lint", "--changed"}
      end
    end
    result = bounded_cli(root, _156_())
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  return with_cleanup(_154_, _155_)
end
local function changed_config()
  return "{:lint {:rules {\"core-require\" :off \"defn-args-newline\" :off \"function-shape\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
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
local function changed_mode_scenario(mode)
  local root = vim.fn.tempname()
  local source_path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  local subdir = (root .. "/nested")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir(subdir, "p")
  local function _159_()
    return vim.fn.delete(root, "rf")
  end
  local function _160_()
    git_init(root)
    write_file(config_path, changed_config())
    write_file(source_path, changed_source("base"))
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    if ((mode == "modified") or (mode == "subdir")) then
      write_file(source_path, changed_source("changed"))
    else
      if (mode == "both") then
        changed_mode_both(root, source_path)
      else
        if (mode == "staged") then
          changed_mode_staged(root, source_path)
        else
        end
      end
    end
    if (mode == "untracked") then
      write_file((root .. "/new file.fnl"), "(defn new [] (if z (do (foo) (bar)) nil))\n")
    else
    end
    if (mode == "rename") then
      changed_mode_rename(root)
    else
    end
    local cwd
    if (mode == "subdir") then
      cwd = subdir
    else
      cwd = root
    end
    local result = bounded_cli(cwd, {"lint", "--changed"})
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  return with_cleanup(_159_, _160_)
end
local function base_mode_scenario()
  local root = vim.fn.tempname()
  local source_path = (root .. "/a.fnl")
  vim.fn.mkdir(root, "p")
  local function _167_()
    return vim.fn.delete(root, "rf")
  end
  local function _168_()
    git_init(root)
    write_file((root .. "/.fnl-extras.fnl"), changed_config())
    write_file(source_path, changed_source("base"))
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    write_file(source_path, changed_source("changed"))
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "changed"})
    local result = bounded_cli(root, {"lint", "--base", "HEAD~1"})
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  return with_cleanup(_167_, _168_)
end
local function file_size_changed_mode_scenario()
  local root = vim.fn.tempname()
  local changed_path = (root .. "/changed.fnl")
  local unchanged_path = (root .. "/unchanged.fnl")
  local config = "{:lint {:max-code-lines 2 :rules {\"core-require\" :off \"function-shape\" :off \"if-branch-call\" :off \"module-style\" :off \"no-mutation\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
  local base_source = "(local a 1)\n(local b 2)\n(local c 3)\n"
  local changed_source0 = "(local a 9)\n(local b 2)\n(local c 3)\n"
  vim.fn.mkdir(root, "p")
  local function _169_()
    return vim.fn.delete(root, "rf")
  end
  local function _170_()
    git_init(root)
    write_file((root .. "/.fnl-extras.fnl"), config)
    write_file(changed_path, base_source)
    write_file(unchanged_path, base_source)
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    write_file(changed_path, changed_source0)
    local result = bounded_cli(root, {"lint", "--changed"})
    local findings = finding_lines(result.lines)
    local _171_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, line in ipairs(findings) do
        local val_28_
        if string.match(line, "changed%.fnl:.*file%-size") then
          val_28_ = line
        else
          val_28_ = nil
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _171_ = tbl_26_
    end
    local _174_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, line in ipairs(findings) do
        local val_28_
        if string.match(line, "unchanged%.fnl:.*file%-size") then
          val_28_ = line
        else
          val_28_ = nil
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _174_ = tbl_26_
    end
    return {code = result.code, ["changed-file-size"] = #_171_, ["unchanged-file-size"] = #_174_}
  end
  return with_cleanup(_169_, _170_)
end
local function lint_error_repository_scenario(root)
  return write_file((root .. "/a.fnl"), "(if x 1 2)\n")
end
local function lint_error_configured_scenario(root)
  local _ = git_init(root)
  local _0 = write_file((root .. "/.fnl-extras.fnl"), "{:lint {:rules {\"core-require\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :off \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}")
  local _1 = write_file((root .. "/a.fnl"), "(if x 1 2)\n")
  local _2 = git_run(root, {"add", "."})
  return git_run(root, {"commit", "-qm", "base"})
end
local function lint_error_mode_scenario(mode)
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  local function _177_()
    return vim.fn.delete(root, "rf")
  end
  local function _178_()
    if (mode == "git") then
      lint_error_repository_scenario(root)
    else
      lint_error_configured_scenario(root)
    end
    local args
    if (mode == "base") then
      args = {"lint", "--base", "missing-ref"}
    else
      if ((mode == "changed") or (mode == "git")) then
        args = {"lint", "--changed"}
      else
        args = {"lint"}
      end
    end
    local result = bounded_cli(root, args)
    local line = (result.lines[1] or "")
    return {code = result.code, line = line, ["timed-out?"] = result["timed-out?"]}
  end
  return with_cleanup(_177_, _178_)
end
local function stale_exclusion_scenario(mode)
  local root = vim.fn.tempname()
  local a_path = (root .. "/a.fnl")
  local b_path = (root .. "/b.fnl")
  local gone_path = (root .. "/gone.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  local config
  if ((mode == "untouched") or (mode == "all")) then
    config = "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"b.fnl > missing\" :reason \"old intentional branch\"}]}}"
  else
    if (mode == "modified") then
      config = "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"a.fnl > missing\" :reason \"old intentional branch\"}]}}"
    else
      config = "{:lint {:rules {\"module-style\" :off} :exclusions [{:rule \"if-branch-call\" :form \"gone.fnl > missing\" :reason \"old intentional branch\"}]}}"
    end
  end
  vim.fn.mkdir(root, "p")
  local function _184_()
    return vim.fn.delete(root, "rf")
  end
  local function _185_()
    git_init(root)
    write_file(config_path, config)
    write_file(a_path, "(if x (do (foo) (bar)) nil)\n")
    write_file(b_path, "(if y (do (baz) (qux)) nil)\n")
    write_file(gone_path, "(if z (do (old) (code)) nil)\n")
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    if ((mode == "untouched") or (mode == "all")) then
      write_file(a_path, "(if changed (do (foo) (bar)) nil)\n")
    else
      if (mode == "modified") then
        write_file(a_path, "(if changed (do (foo) (bar)) nil)\n")
      else
        git_run(root, {"rm", "-q", "gone.fnl"})
      end
    end
    local result
    local function _188_()
      if (mode == "all") then
        return {"lint", "--all"}
      else
        return {"lint", "--changed"}
      end
    end
    result = bounded_cli(root, _188_())
    return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
  end
  return with_cleanup(_184_, _185_)
end
local function shallow_clone_scenario(mode)
  local source = vim.fn.tempname()
  local clone = vim.fn.tempname()
  local config = "{:lint {:rules {\"module-style\" :off}}}"
  local clone_command = ("git clone --depth 1 " .. vim.fn.shellescape(("file://" .. source)) .. " " .. vim.fn.shellescape(clone) .. " </dev/null 2>&1")
  vim.fn.mkdir(source, "p")
  local function _189_()
    vim.fn.delete(source, "rf")
    return vim.fn.delete(clone, "rf")
  end
  local function _190_()
    git_init(source)
    write_file((source .. "/.fnl-extras.fnl"), config)
    write_file((source .. "/a.fnl"), "(if x 1 2)\n")
    git_run(source, {"add", "."})
    git_run(source, {"commit", "-qm", "base"})
    local clone_result = bounded_command(clone_command)
    if (0 ~= clone_result.code) then
      return {code = clone_result.code, lines = clone_result.lines, ["timed-out?"] = clone_result["timed-out?"]}
    else
      local result
      local function _191_()
        if (mode == "all") then
          return {"lint", "--all"}
        else
          return {"lint", "--changed"}
        end
      end
      result = bounded_cli(clone, _191_())
      return {code = result.code, lines = result.lines, ["timed-out?"] = result["timed-out?"]}
    end
  end
  return with_cleanup(_189_, _190_)
end
local function default_lint_scenario(mode)
  local root = vim.fn.tempname()
  local config = (root .. "/.fnl-extras.fnl")
  local warn = (root .. "/warning.fnl")
  local config_text = "{:lint {:rules {\"core-require\" :off \"function-shape\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
  vim.fn.mkdir(root, "p")
  local function _193_()
    return vim.fn.delete(root, "rf")
  end
  local function _194_()
    write_file(config, config_text)
    write_file(warn, "(if x (do (foo) (bar)) nil)\n")
    if (mode == "git") then
      local _ = git_init(root)
      local _0 = git_run(root, {"add", "."})
      local _1 = git_run(root, {"commit", "-qm", "base"})
      local result = bounded_cli(root, {"lint"})
      return {code = result.code, lines = result.lines}
    else
      local result = bounded_cli(root, {"lint"})
      return {code = result.code, lines = result.lines}
    end
  end
  return with_cleanup(_193_, _194_)
end
local function default_lint_all_files_scenario()
  local root = vim.fn.tempname()
  local config = (root .. "/.fnl-extras.fnl")
  local warn = (root .. "/warning.fnl")
  local error = (root .. "/error.fnl")
  local config_text = "{:lint {:rules {\"core-require\" :off \"function-shape\" :off \"if-branch-call\" :warning \"module-style\" :off \"one-is-per-testing\" :error \"spec-direct-require\" :off \"spec-macro-import\" :off \"spec-no-module\" :off}}}"
  vim.fn.mkdir(root, "p")
  local function _196_()
    return vim.fn.delete(root, "rf")
  end
  local function _197_()
    git_init(root)
    write_file(config, config_text)
    write_file(warn, "(if x (do (foo) (bar)) nil)\n")
    write_file(error, "(testing \"x\" (is 1) (is 2))\n")
    git_run(root, {"add", "."})
    git_run(root, {"commit", "-qm", "base"})
    local result = bounded_cli(root, {"lint"})
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_196_, _197_)
end
local function _198_()
  local function _199_()
    local result = default_lint_all_files_scenario()
    local text = table.concat(result.lines, "\n")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((1 == result.code) and string.match(text, "warning%.fnl:1:7: warning if%-branch%-call") and string.match(text, "error%.fnl:1:1: error one%-is%-per%-testing"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (. result \"code\")) (string.match text \"warning%.fnl:1:7: warning if%-branch%-call\") (string.match text \"error%.fnl:1:1: error one%-is%-per%-testing\"))")
    return true
  end
  require("plenary.busted").it("default lint reports findings from all committed files", _199_)
  local function _200_()
    local result = default_lint_scenario("no-git")
    local text = table.concat(result.lines, "\n")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((0 == result.code) and string.match(text, "warning%.fnl:1:7: warning if%-branch%-call") and not string.match(text, "lint requires a Git repository"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (string.match text \"warning%.fnl:1:7: warning if%-branch%-call\") (not (string.match text \"lint requires a Git repository\")))")
    return true
  end
  return require("plenary.busted").it("default lint works without a Git repository", _200_)
end
require("plenary.busted").describe("lint-default-selection", _198_)
local function _201_()
  local function _202_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, ["timed-out?"] = false}
    local actual_7_auto = changed_mode_scenario("clean")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("clean repositories produce no changed-mode findings", _202_)
  local function _203_()
    local result = changed_mode_scenario("modified")
    local findings = finding_lines(result.lines)
    local assert_28_auto = require("luassert")
    local value_29_auto = ((0 == result.code) and (1 == #findings) and (2 == #result.lines) and string.match(result.lines[2], "defn:first"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (= 1 (length findings)) (= 2 (length (. result \"lines\"))) (string.match (. result \"lines\" 2) \"defn:first\"))")
    return true
  end
  require("plenary.busted").it("modified files report only the warning whose form intersects changed lines", _203_)
  local function _204_()
    local result = changed_mode_scenario("staged")
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #finding_lines(result.lines)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("staged-only changes are selected", _204_)
  local function _205_()
    local result = changed_mode_scenario("both")
    local assert_5_auto = require("luassert")
    local expected_6_auto = 2
    local actual_7_auto = #finding_lines(result.lines)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("staged and unstaged changes are unioned against HEAD", _205_)
  local function _206_()
    local result = changed_mode_scenario("untracked")
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #finding_lines(result.lines)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("untracked files are selected as whole files", _206_)
  local function _207_()
    local result = changed_mode_scenario("rename")
    local findings = finding_lines(result.lines)
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == #findings) and string.match(result.lines[1], "renamed file%.fnl"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (length findings)) (string.match (. result \"lines\" 1) \"renamed file%.fnl\"))")
    return true
  end
  require("plenary.busted").it("renamed destinations are selected as whole files and paths with spaces survive", _207_)
  local function _208_()
    local root_result = changed_mode_scenario("modified")
    local subdir_result = changed_mode_scenario("subdir")
    local root = finding_lines(root_result.lines)
    local subdir = finding_lines(subdir_result.lines)
    local assert_28_auto = require("luassert")
    local value_29_auto = (not root_result["timed-out?"] and not subdir_result["timed-out?"] and (#root == #subdir))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. root-result \"timed-out?\")) (not (. subdir-result \"timed-out?\")) (= (length root) (length subdir)))")
    return true
  end
  require("plenary.busted").it("subdirectory invocation matches root changed-mode selection without timing out", _208_)
  local function _209_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = file_size_changed_mode_scenario()["changed-file-size"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("changed oversized files report exactly one file-size finding", _209_)
  local function _210_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = file_size_changed_mode_scenario()["unchanged-file-size"]
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("unchanged oversized files do not report file-size findings in changed mode", _210_)
end
require("plenary.busted").describe("git-changed-selection", _201_)
local function _211_()
  local function _212_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 1
    local actual_7_auto = #finding_lines(base_mode_scenario().lines)
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("base ref includes committed changes since the selected base", _212_)
  local function _213_()
    local result = lint_error_mode_scenario("git")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and string.match(result.line, "lint requires a Git repository"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (. result \"line\") \"lint requires a Git repository\"))")
    return true
  end
  require("plenary.busted").it("changed lint outside a Git repository exits two with the repository message", _213_)
  local function _214_()
    local result = invalid_git_scenario("all")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((0 == result.code) and ("" == result.line))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 0 (. result \"code\")) (= \"\" (. result \"line\")))")
    return true
  end
  require("plenary.busted").it("lint all works in an empty Git directory without resolving Git state", _214_)
  local function _215_()
    local result = invalid_git_scenario("changed")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and string.match(result.line, "lint requires a Git repository"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (. result \"line\") \"lint requires a Git repository\"))")
    return true
  end
  require("plenary.busted").it("changed lint rejects an empty Git directory with the repository message", _215_)
  local function _216_()
    local result = lint_error_mode_scenario("base")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and string.match(result.line, "missing%-ref"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (string.match (. result \"line\") \"missing%-ref\"))")
    return true
  end
  require("plenary.busted").it("an unknown base ref exits two and names the ref", _216_)
  local function _217_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl:1:1: error one-is-per-testing: each testing form must contain exactly one is", "  exclusion: {:rule \"one-is-per-testing\" :form \"a.fnl > top#1 > testing#1\" :reason \"explain why this is intentional\"}"}, ["timed-out?"] = false}
    local actual_7_auto = unborn_git_scenario("all")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("all mode lints an unborn repository without resolving HEAD", _217_)
  local function _218_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"unknown base ref: HEAD"}, ["timed-out?"] = false}
    local actual_7_auto = unborn_git_scenario("changed")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("changed mode reports the unknown unborn HEAD base", _218_)
end
require("plenary.busted").describe("git-base-and-errors", _211_)
local function _219_()
  local function _220_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, ["timed-out?"] = false}
    local actual_7_auto = stale_exclusion_scenario("untouched")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("an untouched file's stale exclusion does not fail changed mode", _220_)
  local function _221_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: a.fnl > missing"}, ["timed-out?"] = false}
    local actual_7_auto = stale_exclusion_scenario("modified")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a stale exclusion in a modified file fails changed mode with its stale line", _221_)
  local function _222_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: gone.fnl > missing"}, ["timed-out?"] = false}
    local actual_7_auto = stale_exclusion_scenario("deleted")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("a deleted file's exclusion is stale in changed mode", _222_)
  local function _223_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {".fnl-extras.fnl:1:1: error if-branch-call: stale exclusion: b.fnl > missing"}, ["timed-out?"] = false}
    local actual_7_auto = stale_exclusion_scenario("all")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("all mode reports stale exclusions regardless of file scope", _223_)
end
require("plenary.busted").describe("stale-exclusion-scope", _219_)
local function _224_()
  local function _225_()
    local result = shallow_clone_scenario("changed")
    local line = (result.lines[1] or "")
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result["timed-out?"] and (2 == result.code) and string.match(line, "full clone"))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"timed-out?\")) (= 2 (. result \"code\")) (string.match line \"full clone\"))")
    return true
  end
  require("plenary.busted").it("a shallow clone exits two with the full-clone message", _225_)
  local function _226_()
    local result = shallow_clone_scenario("all")
    local assert_28_auto = require("luassert")
    local value_29_auto = (not result["timed-out?"] and (0 == result.code) and (0 == #result.lines))
    assert_28_auto.is_truthy(value_29_auto, "(and (not (. result \"timed-out?\")) (= 0 (. result \"code\")) (= 0 (length (. result \"lines\"))))")
    return true
  end
  return require("plenary.busted").it("all mode lints a shallow clone without requiring a full clone", _226_)
end
require("plenary.busted").describe("shallow-clone", _224_)
local function _227_()
  local function _228_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = 0
    local actual_7_auto = default_lint_scenario("no-git").code
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("default all mode does not require a Git repository", _228_)
end
require("plenary.busted").describe("lint-all-git-boundary", _227_)
local function _229_()
  local function _230_()
    local result = align_bindings_cli_scenario()
    local assert_28_auto = require("luassert")
    local value_29_auto = ((1 == result["check-code"]) and vim.deep_equal({"a.fnl"}, result["check-lines"]) and (0 == result["write-code"]) and vim.deep_equal({"a.fnl"}, result["write-lines"]) and (result.expected == result.content))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 1 (. result \"check-code\")) (vim.deep_equal [\"a.fnl\"] (. result \"check-lines\")) (= 0 (. result \"write-code\")) (vim.deep_equal [\"a.fnl\"] (. result \"write-lines\")) (= (. result \"expected\") (. result \"content\")))")
    return true
  end
  return require("plenary.busted").it("check reports missing binding alignment and write fixes it", _230_)
end
return require("plenary.busted").describe("align-bindings-cli", _229_)
