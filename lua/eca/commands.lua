-- [nfnl] fnl/eca/commands.fnl
local api = require("eca.api")
local function setup(chat_ui)
  local function _1_()
    return chat_ui.toggle()
  end
  api["create-user-command"]("EcaChat", _1_, {desc = "Toggle ECA Chat window"})
  local function _2_()
    return chat_ui.open()
  end
  api["create-user-command"]("EcaChatOpen", _2_, {desc = "Open ECA Chat window"})
  local function _3_()
    return chat_ui.close()
  end
  api["create-user-command"]("EcaChatClose", _3_, {desc = "Close ECA Chat window"})
  local function _4_()
    return chat_ui["clear-messages"]()
  end
  api["create-user-command"]("EcaChatClear", _4_, {desc = "Clear ECA Chat messages"})
  local function _5_()
    return chat_ui["clear-messages"]()
  end
  api["create-user-command"]("EcaChatNew", _5_, {desc = "Start a new ECA Chat"})
  local function _6_()
    return chat_ui["submit-prompt"]()
  end
  api["create-user-command"]("EcaChatSubmit", _6_, {desc = "Submit current prompt"})
  local function _7_()
    return chat_ui["set-loading"](false)
  end
  return api["create-user-command"]("EcaChatStop", _7_, {desc = "Stop current ECA response"})
end
return {setup = setup}
