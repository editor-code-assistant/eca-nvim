-- [nfnl] fnl/nfnl/config.fnl
local _local_1_ = require("eca.nfnl.module")
local autoload = _local_1_.autoload
local define = _local_1_.define
local core = autoload("eca.nfnl.core")
local fs = autoload("eca.nfnl.fs")
local str = autoload("eca.nfnl.string")
local fennel = autoload("eca.nfnl.fennel")
local notify = autoload("eca.nfnl.notify")
local vim = _G.vim
local M = define("eca.nfnl.config")
local config_file_name = ".nfnl.fnl"
M.find = function(dir)
  return fs["full-path"](core.first(vim.fs.find(config_file_name, {path = dir, upward = true, type = "file"})))
end
local function under_3f(parent, dir)
  local prefix = (parent .. fs["path-sep"]())
  return ((parent == dir) or (prefix == string.sub(dir, 1, string.len(prefix))))
end
M["owner-filter"] = function(root_dir)
  local cache = {}
  local function _2_(path)
    local dir = fs.basename(path)
    if core["nil?"](cache[dir]) then
      local _3_
      do
        local config_dir = fs.basename(M.find(dir))
        if core["nil?"](config_dir) then
          _3_ = true
        elseif (root_dir == config_dir) then
          _3_ = true
        elseif (under_3f(root_dir, config_dir) and under_3f(config_dir, dir)) then
          _3_ = false
        else
          _3_ = true
        end
      end
      cache[dir] = _3_
    else
    end
    return cache[dir]
  end
  return _2_
end
M["path-dirs"] = function(_6_)
  local rtp_patterns = _6_["rtp-patterns"]
  local runtimepath = _6_.runtimepath
  local base_dirs = _6_["base-dirs"]
  local function _7_(path)
    local function _8_(_241)
      return string.find(path, _241)
    end
    return core.some(_8_, rtp_patterns)
  end
  return core.distinct(core.concat(base_dirs, core.filter(_7_, str.split(runtimepath, ","))))
end
M.default = function(opts)
  local root_dir
  local or_9_ = core.get(opts, "root-dir")
  if not or_9_ then
    local tmp_3_ = vim.fn.getcwd()
    if (nil ~= tmp_3_) then
      local tmp_3_0 = M.find(tmp_3_)
      if (nil ~= tmp_3_0) then
        local tmp_3_1 = fs["full-path"](tmp_3_0)
        if (nil ~= tmp_3_1) then
          or_9_ = fs.basename(tmp_3_1)
        else
          or_9_ = nil
        end
      else
        or_9_ = nil
      end
    else
      or_9_ = nil
    end
  end
  root_dir = (or_9_ or vim.fn.getcwd())
  local dirs = M["path-dirs"]({runtimepath = vim.o.runtimepath, ["rtp-patterns"] = core.get(opts, "rtp-patterns", {(fs["path-sep"]() .. "nfnl$")}), ["base-dirs"] = {root_dir}})
  local function _16_(root_dir0)
    return core.map(fs["join-path"], {{root_dir0, "?.fnl"}, {root_dir0, "?", "init.fnl"}, {root_dir0, "fnl", "?.fnl"}, {root_dir0, "fnl", "?", "init.fnl"}})
  end
  local function _17_(root_dir0)
    return core.map(fs["join-path"], {{root_dir0, "?.fnlm"}, {root_dir0, "?", "init.fnlm"}, {root_dir0, "?", "init-macros.fnlm"}, {root_dir0, "fnl", "?.fnlm"}, {root_dir0, "fnl", "?", "init.fnlm"}, {root_dir0, "fnl", "?", "init-macros.fnlm"}, {root_dir0, "?.fnl"}, {root_dir0, "?", "init.fnl"}, {root_dir0, "?", "init-macros.fnl"}, {root_dir0, "fnl", "?.fnl"}, {root_dir0, "fnl", "?", "init.fnl"}, {root_dir0, "fnl", "?", "init-macros.fnl"}})
  end
  return {["header-comment"] = true, ["header-search-lines"] = 5, ["compiler-options"] = {["error-pinpoint"] = false}, ["orphan-detection"] = {["auto?"] = true, ["ignore-patterns"] = {}}, ["root-dir"] = root_dir, ["fennel-path"] = str.join(";", core.mapcat(_16_, dirs)), ["fennel-macro-path"] = str.join(";", core.mapcat(_17_, dirs)), ["source-file-patterns"] = {".*.fnl", "*.fnl", fs["join-path"]({"**", "*.fnl"})}, ["fnl-path->lua-path"] = fs["fnl-path->lua-path"], verbose = false}
end
M["cfg-fn"] = function(t, opts)
  local default_cfg = M.default(opts)
  local function _18_(path)
    return core["get-in"](t, path, core["get-in"](default_cfg, path))
  end
  return _18_
end
local notified = {}
M["config-file-path?"] = function(path)
  return (config_file_name == fs.filename(path))
end
M["find-and-load"] = function(dir)
  local _19_
  do
    local config_file_path = M.find(dir)
    if config_file_path then
      local root_dir = fs.basename(config_file_path)
      local config_source = vim.secure.read(config_file_path)
      local ok, config
      if core["nil?"](config_source) then
        if not notified[config_file_path] then
          notified[config_file_path] = true
          notify.info(config_file_path, " is not trusted yet. Open it and :trust to enable nfnl.")
        else
        end
        ok, config = false, nil
      elseif (str["blank?"](config_source) or ("{}" == str.trim(config_source))) then
        ok, config = true, {}
      else
        ok, config = pcall(fennel.eval, config_source, {filename = config_file_path})
      end
      if ok then
        _19_ = {config = config, ["root-dir"] = root_dir, cfg = M["cfg-fn"](config, {["root-dir"] = root_dir})}
      else
        if config then
          _19_ = notify.error(config)
        else
          _19_ = nil
        end
      end
    else
      _19_ = nil
    end
  end
  return (_19_ or {})
end
return M
