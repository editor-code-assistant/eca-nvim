-- [nfnl] fnl/eca/init.fnl
local api = require("eca.api")
local commands = require("eca.commands")
local function setup(opts)
  api["set-plugin-opts"]((opts or {}))
  return commands.setup(api)
end
return {setup = setup}
