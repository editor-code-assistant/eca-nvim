-- [nfnl] fnl/eca/init.fnl
local api = require("eca.api")
local builder = require("eca.ui.builder")
local commands = require("eca.commands")
local chat_ui = nil
local function default_on_submit(text)
  if chat_ui then
    chat_ui["append-message"]({id = tostring(os.time()), role = "user", content = text})
    chat_ui["set-loading"](true)
    local function _1_()
      if chat_ui then
        chat_ui["append-message"]({id = ("reply-" .. tostring(os.time())), role = "assistant", content = ("You said: " .. text .. "\n\n(This is a mock response \226\128\148 connect ECA server for real responses)")})
        return chat_ui["set-loading"](false)
      else
        return nil
      end
    end
    return api.defer(_1_, 500)
  else
    return nil
  end
end
local function setup(opts)
  local user_opts = (opts or {})
  chat_ui = builder["create-chat-ui"]({api = api, ["on-submit"] = (user_opts["on-submit"] or default_on_submit), opts = {ui = (user_opts.ui or {})}})
  return commands.setup(chat_ui)
end
return {setup = setup}
