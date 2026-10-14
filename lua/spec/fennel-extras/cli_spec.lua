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
      write_file(good, "(when x\ny)\n")
      local result = run_cli(root, {"format", "--write", "--parser", "eca.nfnl.fennel", "good.fnl"})
      return {code = result.code, lines = result.lines, good = read_file(good)}
    else
      if (mode == "formatted") then
        write_file(good, "(when x\n  y)\n")
        local result = run_cli(root, {"format", "--write", "good.fnl"})
        return {code = result.code, lines = result.lines, good = read_file(good), ["entry-count"] = #vim.fn.globpath(root, "*", false, true)}
      else
        write_file(good, "(when x\ny)\n")
        write_file(bad, "(x")
        local result = run_cli(root, {"format", "--write", "good.fnl", "bad.fnl"})
        return {code = result.code, lines = result.lines, good = read_file(good), bad = read_file(bad)}
      end
    end
  end
  return with_cleanup(_7_, _8_)
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
      write_file(config_path, "{:indents {\"deftest\" [[:block 1]]}}")
      write_file(src_file, "(deftest t\n(foo))\n")
      local result = run_cli(root, {"format", "--write", "src/a.fnl"})
      return {code = result.code, lines = result.lines, content = read_file(src_file)}
    else
      if (mode == "exclude") then
        write_file(config_path, "{:exclude [\"skip\"]}\n")
        write_file(src_file, "(when x\n  y)\n")
        write_file(skip_file, "(when x\ny)\n")
        local result = run_cli(root, {"format", "--write"})
        return {code = result.code, lines = result.lines, content = read_file(skip_file)}
      else
        if (mode == "paths") then
          write_file(config_path, "{:paths [\"src\"]}")
          write_file(src_file, "(when x\ny)\n")
          write_file(skip_file, "(when x\ny)\n")
          local result = run_cli(root, {"format", "--write"})
          return {code = result.code, lines = result.lines, src = read_file(src_file), skip = read_file(skip_file)}
        else
          write_file(config_path, "{:colour 1}")
          local result = run_cli(root, {"format", "--check", "src/a.fnl"})
          return {code = result.code, lines = result.lines}
        end
      end
    end
  end
  return with_cleanup(_11_, _12_)
end
local function _16_()
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, content = "(when x\n  y)\n", ["expected-code"] = 0, ["expected-lines"] = {}}
    local actual_7_auto = check_scenario("(when x\n  y)\n", 0, {})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("returns zero and no lines for an already-formatted project", _17_)
  local function _18_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, content = "(when x\ny)\n", ["expected-code"] = 1, ["expected-lines"] = {"a.fnl"}}
    local actual_7_auto = check_scenario("(when x\ny)\n", 1, {"a.fnl"})
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("returns one and leaves an unformatted file unchanged", _18_)
end
require("plenary.busted").describe("check", _16_)
local function _19_()
  local function _20_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"good.fnl"}, good = "(when x\n  y)\n"}
    local actual_7_auto = write_scenario("good")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rewrites an unformatted file and reports its relative path", _20_)
  local function _21_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, good = "(when x\n  y)\n", ["entry-count"] = 1}
    local actual_7_auto = write_scenario("formatted")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not rewrite an already-formatted file or leave a temp file", _21_)
  local function _22_()
    local result = write_scenario("error")
    local assert_28_auto = require("luassert")
    local value_29_auto = ((2 == result.code) and ("(when x\ny)\n" == result.good) and ("(x" == result.bad) and (1 == #result.lines) and string.match(result.lines[1], "^bad%.fnl:[0-9]+:[0-9]+: .*"))
    assert_28_auto.is_truthy(value_29_auto, "(and (= 2 (. result \"code\")) (= \"(when x\ny)\n\" (. result \"good\")) (= \"(x\" (. result \"bad\")) (= 1 (length (. result \"lines\"))) (string.match (. result \"lines\" 1) \"^bad%.fnl:[0-9]+:[0-9]+: .*\"))")
    return true
  end
  return require("plenary.busted").it("formats all files before writing and leaves the good file unchanged on error", _22_)
end
require("plenary.busted").describe("write", _19_)
local function _23_()
  local function _24_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"src/a.fnl"}, content = "(deftest t\n  (foo))\n"}
    local actual_7_auto = config_scenario("indent")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured indentation rules", _24_)
  local function _25_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, content = "(when x\ny)\n"}
    local actual_7_auto = config_scenario("exclude")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("skips files under configured exclude prefixes", _25_)
  local function _26_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"src/a.fnl"}, src = "(when x\n  y)\n", skip = "(when x\ny)\n"}
    local actual_7_auto = config_scenario("paths")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured paths for a no-argument run", _26_)
  local function _27_()
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
  return require("plenary.busted").it("returns one config error line for an invalid configuration", _27_)
end
require("plenary.busted").describe("config", _23_)
local function extension_scenario(extension)
  local root = vim.fn.tempname()
  local path = (root .. "/source" .. extension)
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _28_()
    return vim.fn.delete(root, "rf")
  end
  local function _29_()
    write_file(config_path, ("{:extensions [\"" .. extension .. "\"]}"))
    if (extension == ".fnl") then
      write_file(path, "(when x\ny)\n")
      write_file((root .. "/source.fnlm"), "(when y\nz)\n")
    else
      write_file(path, "(when x\ny)\n")
    end
    local result = run_cli(root, {"format", "--check"})
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_28_, _29_)
end
local function default_path_scenario()
  local root = vim.fn.tempname()
  local path = (root .. "/source.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _31_()
    return vim.fn.delete(root, "rf")
  end
  local function _32_()
    write_file(path, "(when x\ny)\n")
    local result = run_cli(root, {"format", "--write"})
    return {code = result.code, lines = result.lines, content = read_file(path)}
  end
  return with_cleanup(_31_, _32_)
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
  local function _33_()
    return vim.fn.delete(root, "rf")
  end
  local function _34_()
    write_file((root .. "/.fnl-extras.fnl"), "{:paths [\"fnl\"] :skip-dotfiles false}")
    write_file(hidden_file, "(when x\ny)\n")
    write_file(nested_file, "(when x\ny)\n")
    write_file(git_file, "(when x\ny)\n")
    local result = run_cli(root, {"format", "--check"})
    return {code = result.code, lines = result.lines, hidden = vim.loop.fs_stat(hidden_file).type, nested = vim.loop.fs_stat(nested_file).type, git = read_file(git_file)}
  end
  return with_cleanup(_33_, _34_)
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
  local function _35_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _36_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result = run_cli(root, {"format", "--write"})
    return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
  end
  return with_cleanup(_35_, _36_)
end
local function follow_directory_symlink_scenario(mode)
  local root = vim.fn.tempname()
  local outside = vim.fn.tempname()
  local link = (root .. "/linkdir")
  local target = (outside .. "/a.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir(outside, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _37_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _38_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(outside, link))
    local result
    local function _39_()
      if (mode == "check") then
        return {"format", "--check"}
      else
        return {"format", "--write"}
      end
    end
    result = run_cli(root, _39_())
    if (mode == "check") then
      return {code = result.code, lines = result.lines, target = read_file(target)}
    else
      return {code = result.code, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
    end
  end
  return with_cleanup(_37_, _38_)
end
local function parser_scenario(mode)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _41_()
    return vim.fn.delete(root, "rf")
  end
  local function _42_()
    write_file(path, "(when x\ny)\n")
    write_file(config_path, "{:parser \"missing.parser.module\"}")
    local result
    local function _43_()
      if (mode == "config") then
        return {"format", "--check", "a.fnl"}
      else
        return {"format", "--check", "--parser", "eca.nfnl.fennel", "a.fnl"}
      end
    end
    result = run_cli(root, _43_())
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_41_, _42_)
end
local function rule_config_scenario(config, source, expected)
  local root = vim.fn.tempname()
  local path = (root .. "/a.fnl")
  local config_path = (root .. "/.fnl-extras.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _44_()
    return vim.fn.delete(root, "rf")
  end
  local function _45_()
    write_file(config_path, config)
    write_file(path, source)
    local result = run_cli(root, {"format", "--write", "a.fnl"})
    return {code = result.code, lines = result.lines, content = read_file(path), expected = expected}
  end
  return with_cleanup(_44_, _45_)
end
local function config_discovery_scenario(mode)
  local root = vim.fn.tempname()
  local config_path = (root .. "/.fnl-extras.fnl")
  local source_path = (root .. "/a.fnl")
  local config = "{:skip-dotfiles false\n:paths [\".\"]}\n"
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _46_()
    return vim.fn.delete(root, "rf")
  end
  local function _47_()
    write_file(config_path, config)
    write_file(source_path, "(when x\ny)\n")
    local result
    local function _48_()
      if (mode == "check") then
        return {"format", "--check"}
      else
        return {"format", "--write"}
      end
    end
    result = run_cli(root, _48_())
    return {code = result.code, lines = result.lines, config = read_file(config_path), source = read_file(source_path)}
  end
  return with_cleanup(_46_, _47_)
end
local function _49_()
  local function _50_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"source.fnl"}}
    local actual_7_auto = extension_scenario(".fnl")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses only configured extensions during discovery", _50_)
  local function _51_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"source.fnlx"}}
    local actual_7_auto = extension_scenario(".fnlx")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("discovers a configured non-default extension", _51_)
  local function _52_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"source.fnl"}, content = "(when x\n  y)\n"}
    local actual_7_auto = default_path_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("walks the current directory when paths are absent from config and CLI", _52_)
  local function _53_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"fnl/.hidden.fnl", "fnl/.hidden/nested.fnl"}, hidden = "file", nested = "file", git = "(when x\ny)\n"}
    local actual_7_auto = dotfiles_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("formats dotfiles and dot-directories when skip-dotfiles is false but never .git", _53_)
  local function _54_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"fnl/link.fnl"}, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_symlink_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("follows file symlinks to real targets and preserves the symlink", _54_)
  local function _55_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"linkdir/a.fnl"}, target = "(when x\ny)\n"}
    local actual_7_auto = follow_directory_symlink_scenario("check")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("reports files under followed directory symlinks by logical path", _55_)
  local function _56_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_directory_symlink_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("writes files under followed directory symlinks to their real targets", _56_)
  local function _57_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"could not require parser module: missing.parser.module"}}
    local actual_7_auto = parser_scenario("config")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses the parser named by config when no CLI parser is given", _57_)
  local function _58_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}}
    local actual_7_auto = parser_scenario("flag")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("CLI parser overrides the parser named by config", _58_)
end
require("plenary.busted").describe("new-configuration", _49_)
local function symlink_loop_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local file = (fnl_dir .. "/a.fnl")
  local loop_path = (fnl_dir .. "/loop")
  local script = (vim.fn.getcwd() .. "/scripts/fennel-extras")
  vim.fn.mkdir(fnl_dir, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _59_()
    return vim.fn.delete(root, "rf")
  end
  local function _60_()
    write_file(file, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(root, loop_path))
    local command = ("cd " .. vim.fn.shellescape(root) .. " && perl -e 'alarm shift; exec @ARGV' 10 " .. vim.fn.shellescape(script) .. " format --check")
    local lines = vim.fn.systemlist({"sh", "-c", command})
    return {code = vim.v.shell_error, lines = lines}
  end
  return with_cleanup(_59_, _60_)
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
  local function _61_()
    vim.fn.setfperm(read_only, "rwxr-xr-x")
    return vim.fn.delete(root, "rf")
  end
  local function _62_()
    write_file(good, "(when x\ny)\n")
    write_file(blocked, "(when y\nz)\n")
    vim.fn.setfperm(read_only, "r-xr-xr-x")
    local probe_file = io.open(probe, "w")
    if probe_file then
      probe_file:close()
      vim.fn.delete(probe)
      return {["skipped-root"] = true}
    else
      local result = run_cli(root, {"format", "--write"})
      return {code = result.code, ["a-unchanged"] = (read_file(good) == "(when x\ny)\n")}
    end
  end
  return with_cleanup(_61_, _62_)
end
local function dotfile_scenario(mode)
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  vim.fn.mkdir(fnl_dir, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _64_()
    return vim.fn.delete(root, "rf")
  end
  local function _65_()
    if (mode == "config") then
      write_file((root .. "/.fnl-extras.fnl"), "{}\n")
      write_file((fnl_dir .. "/a.fnl"), "(when x\n  y)\n")
      local result = run_cli(root, {"format", "--check", "."})
      return {code = result.code, lines = result.lines}
    else
      write_file((root .. "/.x.fnl"), "(when x\n  y)\n")
      local result = run_cli(root, {"format", "--check", "."})
      return {code = result.code, lines = result.lines}
    end
  end
  return with_cleanup(_64_, _65_)
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
  local function _67_()
    vim.fn.delete(root, "rf")
    return vim.fn.delete(outside, "rf")
  end
  local function _68_()
    write_file(good, "(when x\n  y)\n")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result
    local function _69_()
      if (mode == "write") then
        return {"format", "--write"}
      else
        return {"format", "--check", "fnl/link.fnl"}
      end
    end
    result = run_cli(root, _69_())
    return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
  end
  return with_cleanup(_67_, _68_)
end
local function follow_symlink_dedupe_scenario()
  local root = vim.fn.tempname()
  local target = (root .. "/a.fnl")
  local link = (root .. "/b.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _70_()
    return vim.fn.delete(root, "rf")
  end
  local function _71_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result = run_cli(root, {"format", "--write"})
    return {code = result.code, lines = result.lines, ["link-type"] = vim.loop.fs_lstat(link).type, target = read_file(target)}
  end
  return with_cleanup(_70_, _71_)
end
local function follow_symlink_cycle_scenario()
  local root = vim.fn.tempname()
  local directory = (root .. "/d")
  local file = (directory .. "/x.fnl")
  local loop_path = (directory .. "/loop")
  vim.fn.mkdir(directory, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _72_()
    return vim.fn.delete(root, "rf")
  end
  local function _73_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(file, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(root, loop_path))
    local result = run_cli(root, {"format", "--check"})
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_72_, _73_)
end
local function follow_symlink_explicit_scenario()
  local root = vim.fn.tempname()
  local target = (root .. "/real.fnl")
  local link = (root .. "/link.fnl")
  vim.fn.mkdir(root, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _74_()
    return vim.fn.delete(root, "rf")
  end
  local function _75_()
    write_file((root .. "/.fnl-extras.fnl"), "{:follow-symlinks true}")
    write_file(target, "(when x\ny)\n")
    assert(vim.loop.fs_symlink(target, link))
    local result = run_cli(root, {"format", "--check", "link.fnl"})
    return {code = result.code, lines = result.lines}
  end
  return with_cleanup(_74_, _75_)
end
local function unreadable_directory_scenario()
  local root = vim.fn.tempname()
  local fnl_dir = (root .. "/fnl")
  local locked = (fnl_dir .. "/locked")
  local good = (fnl_dir .. "/a.fnl")
  vim.fn.mkdir(locked, "p")
  vim.fn.mkdir((root .. "/.git"), "p")
  local function _76_()
    vim.fn.setfperm(locked, "rwxr-xr-x")
    return vim.fn.delete(root, "rf")
  end
  local function _77_()
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
  return with_cleanup(_76_, _77_)
end
local function _79_()
  local function _80_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(when x\n    y)\n", expected = "(when x\n    y)\n"}
    local actual_7_auto = rule_config_scenario("{:indent-width 4}", "(when x\ny)\n", "(when x\n    y)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("uses configured indent-width", _80_)
  local function _81_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(let [x 1]\n     x)\n", expected = "(let [x 1]\n     x)\n"}
    local actual_7_auto = rule_config_scenario("{:builtins false}", "(let [x 1]\nx)\n", "(let [x 1]\n     x)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("disables built-in indentation rules when builtins is false", _81_)
  local function _82_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, content = "(defn x\n      y)\n", expected = "(defn x\n      y)\n"}
    local actual_7_auto = rule_config_scenario("{:prefix-fallbacks false}", "(defn x\ny)\n", "(defn x\n      y)\n")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("disables prefix fallback indentation rules when prefix-fallbacks is false", _82_)
end
require("plenary.busted").describe("configured-formatting-rules", _79_)
local function _83_()
  local function _84_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"a.fnl"}, config = "{:skip-dotfiles false\n:paths [\".\"]}\n", source = "(when x\ny)\n"}
    local actual_7_auto = config_discovery_scenario("check")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not report the discovered config file as a formatting target", _84_)
  local function _85_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, config = "{:skip-dotfiles false\n:paths [\".\"]}\n", source = "(when x\n  y)\n"}
    local actual_7_auto = config_discovery_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("does not rewrite the discovered config file", _85_)
end
require("plenary.busted").describe("config-file-discovery", _83_)
local function _86_()
  local function _87_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"fnl/a.fnl"}}
    local actual_7_auto = symlink_loop_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not recurse through directory symlinks", _87_)
  local function _88_()
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
  require("plenary.busted").it("does not partially write files when a later write fails", _88_)
  local function _90_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}}
    local actual_7_auto = dotfile_scenario("config")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not discover a dotfile config as source", _90_)
  local function _91_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, lines = {"no files found"}}
    local actual_7_auto = dotfile_scenario("source")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("does not discover a dotfile with a Fennel extension", _91_)
  local function _92_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {}, ["link-type"] = "link", target = "(when x\ny)\n"}
    local actual_7_auto = symlink_file_scenario("write")
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("skips symlinked files during no-argument writes", _92_)
  local function _93_()
    local result = symlink_file_scenario("check")
    local lines = result.lines
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 2, ["line-count"] = 1, ["mentions-symlink"] = true}
    local actual_7_auto = {code = result.code, ["line-count"] = #lines, ["mentions-symlink"] = not not string.match((lines[1] or ""), "symlink")}
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("rejects an explicit symlink file argument", _93_)
  local function _94_()
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
  require("plenary.busted").it("reports an unreadable directory", _94_)
  local function _96_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 0, lines = {"a.fnl"}, ["link-type"] = "link", target = "(when x\n  y)\n"}
    local actual_7_auto = follow_symlink_dedupe_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("processes a real file only once when a symlink points to it", _96_)
  local function _97_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"d/x.fnl"}}
    local actual_7_auto = follow_symlink_cycle_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  require("plenary.busted").it("terminates when a followed directory symlink forms a cycle", _97_)
  local function _98_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = {code = 1, lines = {"link.fnl"}}
    local actual_7_auto = follow_symlink_explicit_scenario()
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("follows an explicitly named symlink file", _98_)
end
return require("plenary.busted").describe("edge-cases", _86_)
