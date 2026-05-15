-- [nfnl] fnl/eca/commands.fnl
local nvim = vim.api
local function setup(api)
  local function _1_()
    return api["chat-toggle"]()
  end
  nvim.nvim_create_user_command("EcaChat", _1_, {desc = "Toggle ECA Chat window"})
  local function _2_()
    return api["chat-open"]()
  end
  nvim.nvim_create_user_command("EcaChatOpen", _2_, {desc = "Open ECA Chat window"})
  local function _3_()
    return api["chat-close"]()
  end
  nvim.nvim_create_user_command("EcaChatClose", _3_, {desc = "Close ECA Chat window"})
  local function _4_()
    return api["chat-clear"]()
  end
  nvim.nvim_create_user_command("EcaChatClear", _4_, {desc = "Clear current chat messages"})
  local function _5_()
    return api["chat-open"]()
  end
  nvim.nvim_create_user_command("EcaChatNew", _5_, {desc = "Open a new ECA Chat"})
  local function _6_()
    return api["chat-submit"]()
  end
  nvim.nvim_create_user_command("EcaChatSubmit", _6_, {desc = "Submit current prompt"})
  local function _7_()
    return api["chat-set-status"](nil)
  end
  nvim.nvim_create_user_command("EcaChatStop", _7_, {desc = "Stop current ECA response"})
  local function _8_(cmd)
    if (cmd.args and ("" ~= cmd.args)) then
      return api["chat-set-model"](cmd.args)
    else
      return nil
    end
  end
  return nvim.nvim_create_user_command("EcaChatSetModel", _8_, {desc = "Set the model", nargs = 1})
end
return {setup = setup}
