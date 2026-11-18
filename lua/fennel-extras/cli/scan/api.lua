-- [nfnl] fnl/fennel-extras/cli/scan/api.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.scan.api"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.scan.api"]
end
local scan_path = require("fennel-extras.cli.scan.path")
local cwd
do
  local function cwd0()
    return scan_path.cwd()
  end
  _2amodule_2a["cwd"] = cwd0
  cwd = _2amodule_2a.cwd
end
local relative
do
  local function relative0(root, path)
    return scan_path.relative(root, path)
  end
  _2amodule_2a["relative"] = relative0
  relative = _2amodule_2a.relative
end
local realpath
do
  local function realpath0(uv, path)
    return scan_path.realpath(uv, path)
  end
  _2amodule_2a["realpath"] = realpath0
  realpath = _2amodule_2a.realpath
end
return nil
