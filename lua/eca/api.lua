-- [nfnl] fnl/eca/api.fnl
local self = {}
local chats = {}
local plugin_opts = {}
self["resolve-chat"] = function()
  local current = chats[vim.api.nvim_get_current_buf()]
  local or_1_ = current
  if not or_1_ then
    local found = nil
    for _, chat in pairs(chats) do
      if (not found and chat["is-open?"]()) then
        found = chat
      else
      end
    end
    or_1_ = found
  end
  return or_1_
end
self["register-chat"] = function(chat)
  local buf_id = chat["get-buf-id"]()
  if buf_id then
    chats[buf_id] = chat
    return nil
  else
    return nil
  end
end
self["chat-open"] = function()
  local existing = self["resolve-chat"]()
  if not (existing and existing["is-open?"]()) then
    local builder = require("eca.ui.builder")
    local chat_ui = builder["create-chat-ui"]({["on-submit"] = (plugin_opts["on-submit"] or self["default-on-submit"]), ["on-stop"] = (plugin_opts["on-stop"] or self["default-on-stop"]), opts = {ui = (plugin_opts.ui or {}), keymaps = (plugin_opts.keymaps or {{mode = "i", lhs = "<C-s>", rhs = "<cmd>EcaChatSubmit<CR>"}, {mode = "n", lhs = "<CR>", rhs = "<cmd>EcaChatSubmit<CR>"}})}})
    chat_ui.open()
    self["register-chat"](chat_ui)
    chat_ui["set-welcome"]("Welcome to ECA Chat")
    chat_ui["update-header"]({{title = "model", value = "claude"}, {title = "behavior", value = "agent"}})
    return chat_ui["update-footer"]({{value = "Testing assoc-some in @shared."}, {value = "12.4K / 200K ($0.03)"}})
  else
    return nil
  end
end
self["chat-close"] = function()
  local chat = self["resolve-chat"]()
  if chat then
    return chat.close()
  else
    return nil
  end
end
self["chat-toggle"] = function()
  local chat = self["resolve-chat"]()
  if (chat and chat["is-open?"]()) then
    return chat.close()
  else
    return self["chat-open"]()
  end
end
self["chat-submit"] = function()
  local chat = self["resolve-chat"]()
  if chat then
    return chat["submit-prompt"]()
  else
    return nil
  end
end
self["chat-clear"] = function()
  local chat = self["resolve-chat"]()
  if chat then
    return chat["clear-messages"]()
  else
    return nil
  end
end
self["chat-set-model"] = function(model)
  local chat = self["resolve-chat"]()
  if chat then
    return chat["update-header-item"]("model", model)
  else
    return nil
  end
end
self["chat-set-status"] = function(text)
  local chat = self["resolve-chat"]()
  if chat then
    return chat["set-status"](text)
  else
    return nil
  end
end
self["default-on-submit"] = function(text)
  local chat = self["resolve-chat"]()
  if chat then
    chat["append-message"]({id = tostring(os.time()), content = text, prefix = "> "})
    chat["set-loading"](true)
    chat["set-status"]("Generating")
    local reply_id = ("reply-" .. tostring(os.time()))
    local full_text = ("You said: " .. text .. "\n\n(This is a mock streaming response)")
    local chunks = {}
    local chunk_size = 3
    local i = 1
    while (i <= #full_text) do
      local end_idx = math.min((i + chunk_size + -1), #full_text)
      table.insert(chunks, string.sub(full_text, i, end_idx))
      i = (end_idx + 1)
    end
    local function _11_()
      if chat["is-open?"]() then
        chat["append-message"]({id = reply_id, content = "", ["streaming?"] = true})
        local accumulated = ""
        local delay = 0
        for _, chunk in ipairs(chunks) do
          delay = (delay + 50)
          local content_at_send = (accumulated .. chunk)
          accumulated = content_at_send
          local function _12_()
            if chat["is-open?"]() then
              return chat["update-message"](reply_id, content_at_send)
            else
              return nil
            end
          end
          vim.defer_fn(_12_, delay)
        end
        local function _14_()
          if chat["is-open?"]() then
            chat["finish-streaming"](reply_id)
            chat["set-loading"](false)
            return chat["set-status"](nil)
          else
            return nil
          end
        end
        return vim.defer_fn(_14_, (delay + 100))
      else
        return nil
      end
    end
    return vim.defer_fn(_11_, 300)
  else
    return nil
  end
end
self["default-on-stop"] = function()
  local chat = self["resolve-chat"]()
  if chat then
    chat["set-loading"](false)
    return chat["set-status"](nil)
  else
    return nil
  end
end
self["set-plugin-opts"] = function(opts)
  plugin_opts = (opts or {})
  return nil
end
return self
