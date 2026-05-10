-- [nfnl] fnl/eca/init.fnl
local _local_1_ = require("eca.nfnl.module")
local autoload = _local_1_.autoload
local notify = autoload("eca.nfnl.notify")
local function setup()
  return notify.info("Hello, World!")
end
return {setup = setup}
