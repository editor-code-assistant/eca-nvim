-- [nfnl] fnl/nfnl/compile.fnl
local _local_1_ = require("eca.nfnl.module")
local autoload = _local_1_.autoload
local define = _local_1_.define
local core = autoload("eca.nfnl.core")
local str = autoload("eca.nfnl.string")
local fs = autoload("eca.nfnl.fs")
local fennel = autoload("eca.nfnl.fennel")
local notify = autoload("eca.nfnl.notify")
local config = autoload("eca.nfnl.config")
local header = autoload("eca.nfnl.header")
local M = define("eca.nfnl.compile")
M["macro-source?"] = function(_2_)
  local source = _2_.source
  local path = _2_.path
  return ((core["string?"](source) and string.find(source, "%s*;+%s*%[nfnl%-macro%]") and true) or (core["string?"](path) and path and str["ends-with?"](path, ".fnlm")))
end
local function valid_source_files(glob_fn, _3_)
  local root_dir = _3_["root-dir"]
  local cfg = _3_.cfg
  local owner_3f = _3_["owner?"]
  local function _4_(_241)
    return fs["join-path"]({root_dir, _241})
  end
  local function _5_(_241)
    return glob_fn(root_dir, _241)
  end
  return core.filter(owner_3f, core.map(_4_, core.mapcat(_5_, cfg({"source-file-patterns"}))))
end
local function valid_source_file_3f(path, _6_)
  local root_dir = _6_["root-dir"]
  local cfg = _6_.cfg
  local function _7_(_241)
    return fs["glob-matches?"](root_dir, _241, path)
  end
  return core.some(_7_, cfg({"source-file-patterns"}))
end
local function nested_project_file_3f(path, _8_)
  local root_dir = _8_["root-dir"]
  local owner_3f = _8_["owner?"]
  return not (owner_3f or config["owner-filter"](root_dir))(path)
end
M["into-string"] = function(_9_)
  local root_dir = _9_["root-dir"]
  local path = _9_.path
  local cfg = _9_.cfg
  local source = _9_.source
  local batch_3f = _9_["batch?"]
  local opts = _9_
  local macro_3f = M["macro-source?"](opts)
  if (macro_3f and batch_3f) then
    return {status = "macros-are-not-compiled", ["source-path"] = path}
  elseif macro_3f then
    core["clear-table!"](fennel["macro-loaded"])
    return M["all-files"]({["root-dir"] = root_dir, cfg = cfg})
  elseif config["config-file-path?"](path) then
    return {status = "nfnl-config-is-not-compiled", ["source-path"] = path}
  elseif not valid_source_file_3f(path, opts) then
    return {status = "path-is-not-in-source-file-patterns", ["source-path"] = path}
  elseif nested_project_file_3f(path, opts) then
    return {status = "path-is-in-a-nested-nfnl-project", ["source-path"] = path}
  else
    local rel_file_name = path:sub((2 + root_dir:len()))
    local ok, res
    do
      fennel.path = cfg({"fennel-path"})
      fennel["macro-path"] = cfg({"fennel-macro-path"})
      ok, res = pcall(fennel["compile-string"], source, core.merge({filename = rel_file_name, warn = notify.warn}, cfg({"compiler-options"})))
    end
    if ok then
      if cfg({"verbose"}) then
        notify.info("Successfully compiled: ", path)
      else
      end
      local _11_
      if cfg({"header-comment"}) then
        _11_ = header["with-header"](rel_file_name, res)
      else
        _11_ = res
      end
      return {status = "ok", ["source-path"] = path, result = (_11_ .. "\n")}
    else
      if not batch_3f then
        notify.error(res)
      else
      end
      return {status = "compilation-error", error = res, ["source-path"] = path}
    end
  end
end
M["into-file"] = function(_16_)
  local _root_dir = _16_["_root-dir"]
  local cfg = _16_.cfg
  local _source = _16_._source
  local path = _16_.path
  local batch_3f = _16_["batch?"]
  local opts = _16_
  local fnl_path__3elua_path = cfg({"fnl-path->lua-path"})
  local destination_path = fnl_path__3elua_path(path)
  local _let_17_ = M["into-string"](opts)
  local status = _let_17_.status
  local source_path = _let_17_["source-path"]
  local result = _let_17_.result
  local res = _let_17_
  local line, prefix
  if (("ok" == status) and cfg({"header-comment"})) then
    line, prefix = header.read(destination_path, cfg({"header-search-lines"}))
  else
    line, prefix = nil
  end
  if ("ok" ~= status) then
    return res
  elseif (not line or header["tagged?"](line) or not cfg({"header-comment"})) then
    fs.mkdirp(fs.basename(destination_path))
    local function _19_()
      if (prefix and cfg({"header-comment"})) then
        return (prefix .. result)
      else
        return result
      end
    end
    core.spit(destination_path, _19_())
    return {status = "ok", ["source-path"] = source_path, ["destination-path"] = destination_path}
  else
    if not batch_3f then
      notify.warn(destination_path, " was not compiled by nfnl. Delete it manually if you wish to compile into this file.")
    else
    end
    return {status = "destination-exists", ["source-path"] = path, ["destination-path"] = destination_path}
  end
end
M["all-files"] = function(_22_)
  local root_dir = _22_["root-dir"]
  local cfg = _22_.cfg
  local owner_3f = config["owner-filter"](root_dir)
  local function _23_(path)
    return M["into-file"]({["root-dir"] = root_dir, path = path, cfg = cfg, ["owner?"] = owner_3f, source = core.slurp(path), ["batch?"] = true})
  end
  return core.map(_23_, valid_source_files(fs.relglob, {["root-dir"] = root_dir, cfg = cfg, ["owner?"] = owner_3f}))
end
return M
