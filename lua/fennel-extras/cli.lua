-- [nfnl] fnl/fennel-extras/cli.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli"]
end
local runner = require("fennel-extras.cli.run")
local run
do
  local function run0(args, opts)
    return runner.run(args, opts)
  end
  _2amodule_2a["run"] = run0
  run = _2amodule_2a.run
end
return nil
