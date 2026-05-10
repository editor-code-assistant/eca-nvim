-- [nfnl] fnl/nfnl/callback.fnl
local _local_1_ = require("eca.nfnl.module")
local autoload = _local_1_.autoload
local define = _local_1_.define
local core = autoload("eca.nfnl.core")
local str = autoload("eca.nfnl.string")
local fs = autoload("eca.nfnl.fs")
local nvim = autoload("eca.nfnl.nvim")
local compile = autoload("eca.nfnl.compile")
local config = autoload("eca.nfnl.config")
local api = autoload("eca.nfnl.api")
local notify = autoload("eca.nfnl.notify")
local vim = _G.vim
local M = define("eca.nfnl.callback")
M["supported-path?"] = function(file_path)
  local _2_
  if core["string?"](file_path) then
    _2_ = not file_path:find("^[%w-]+:/")
  else
    _2_ = nil
  end
  return (_2_ or false)
end
local function buf_write_callback(ev)
  do
    local path = fs["full-path"](ev.file)
    if M["supported-path?"](path) then
      local _let_4_ = config["find-and-load"](fs.basename(path))
      local config0 = _let_4_.config
      local root_dir = _let_4_["root-dir"]
      local cfg = _let_4_.cfg
      if config0 then
        compile["into-file"]({["root-dir"] = root_dir, cfg = cfg, path = path, source = nvim["get-buf-content-as-string"](ev.buf)})
        if cfg({"orphan-detection", "auto?"}) then
          api["find-orphans"]({dir = root_dir, ["passive?"] = true, config = config0, ["root-dir"] = root_dir, cfg = cfg})
        else
        end
      else
      end
    else
    end
  end
  return nil
end
M["setup-buffer"] = function(ev)
  if (false ~= vim.g["nfnl#compile_on_write"]) then
    vim.api.nvim_create_autocmd({"BufWritePost"}, {group = vim.api.nvim_create_augroup(str.join({"nfnl-on-write", ev.buf}), {}), buffer = ev.buf, callback = buf_write_callback})
  else
  end
  local function _9_(_241)
    return api.dofile(core.first(core.get(_241, "fargs")))
  end
  vim.api.nvim_buf_create_user_command(ev.buf, "NfnlFile", _9_, {desc = "Run the matching Lua file for this Fennel file from disk. Does not recompile the Lua, you must use nfnl to compile your Fennel to Lua first. Calls nfnl.api/dofile under the hood.", force = true, complete = "file", nargs = "?"})
  local function _10_(_241)
    return api["compile-file"]({path = core.first(core.get(_241, "fargs"))})
  end
  vim.api.nvim_buf_create_user_command(ev.buf, "NfnlCompileFile", _10_, {desc = "Executes (nfnl.api/compile-file) which compiles the current file or the one provided as an argumet. The output is written to the appropriate Lua file.", force = true, complete = "file", nargs = "?"})
  local function _11_(_241)
    return api["compile-all-files"](core.first(core.get(_241, "fargs")))
  end
  vim.api.nvim_buf_create_user_command(ev.buf, "NfnlCompileAllFiles", _11_, {desc = "Executes (nfnl.api/compile-all-files) which will, you guessed it, compile all of your files.", force = true, complete = "file", nargs = "?"})
  local function _12_(_241)
    return api["find-orphans"]({dir = core.first(core.get(_241, "fargs"))})
  end
  vim.api.nvim_buf_create_user_command(ev.buf, "NfnlFindOrphans", _12_, {desc = "Executes (nfnl.api/find-orphans) which will find and display all Lua files that no longer have a matching Fennel file.", force = true, complete = "file", nargs = "?"})
  local function _13_(_241)
    return api["delete-orphans"]({dir = core.first(core.get(_241, "fargs"))})
  end
  return vim.api.nvim_buf_create_user_command(ev.buf, "NfnlDeleteOrphans", _13_, {desc = "Executes (nfnl.api/delete-orphans) deletes any orphan Lua files that no longer have their original Fennel file they were compiled from.", force = true, complete = "file", nargs = "?"})
end
return M
