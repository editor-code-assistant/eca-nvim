-- [nfnl] fnl/eca/ui/builder.fnl
local highlights = require("eca.ui.highlights")
local header_bar_widget = require("eca.ui.widgets.header-bar")
local message_list_widget = require("eca.ui.widgets.message-list")
local prompt_area_widget = require("eca.ui.widgets.prompt-area")
local status_bar_widget = require("eca.ui.widgets.status-bar")
local tab_bar_widget = require("eca.ui.widgets.tab-bar")
local function build_canvas(api, buf_id, win_id)
  local buf = buf_id
  local win = win_id
  local function _1_(_, start, _end, lines)
    return api["buf-set-lines"](buf, start, _end, lines)
  end
  local function _2_(_, start, _end)
    return api["buf-get-lines"](buf, start, _end)
  end
  local function _3_(_)
    return api["buf-line-count"](buf)
  end
  local function _4_(_, ns_id, line, col, opts)
    return api["buf-set-extmark"](buf, ns_id, line, col, opts)
  end
  local function _5_(_, ns_id, id)
    return api["buf-del-extmark"](buf, ns_id, id)
  end
  local function _6_(_, ns_id, start, _end, opts)
    return api["buf-get-extmarks"](buf, ns_id, start, _end, opts)
  end
  local function _7_(_, name)
    return api["create-namespace"](name)
  end
  local function _8_(_, scope, key, value)
    if (scope == "win") then
      return api["set-option"]("win", win, key, value)
    elseif (scope == "buf") then
      return api["set-option"]("buf", buf, key, value)
    elseif (scope == "global") then
      return api["set-option"]("global", nil, key, value)
    else
      return nil
    end
  end
  local function _10_(_, scope, key)
    if (scope == "win") then
      return api["get-option"]("win", win, key)
    elseif (scope == "buf") then
      return api["get-option"]("buf", buf, key)
    elseif (scope == "global") then
      return api["get-option"]("global", nil, key)
    else
      return nil
    end
  end
  local function _12_(_)
    return api["win-get-cursor"](win)
  end
  local function _13_(_, line, col)
    return api["win-set-cursor"](win, {line, col})
  end
  local function _14_(_)
    return api["buf-is-valid"](buf)
  end
  local function _15_(_)
    return api["win-is-valid"](win)
  end
  local function _16_(_, ns, group, opts)
    return api["set-hl"](ns, group, opts)
  end
  local function _17_(_)
    return api["win-close"](win)
  end
  local function _18_(_)
    return buf
  end
  local function _19_(_)
    return win
  end
  return {["set-lines"] = _1_, ["get-lines"] = _2_, ["line-count"] = _3_, ["add-extmark"] = _4_, ["del-extmark"] = _5_, ["get-extmarks"] = _6_, ["create-namespace"] = _7_, ["set-option"] = _8_, ["get-option"] = _10_, ["get-cursor"] = _12_, ["set-cursor"] = _13_, ["buf-valid?"] = _14_, ["win-valid?"] = _15_, ["set-hl"] = _16_, ["close-win"] = _17_, ["buf-id"] = _18_, ["win-id"] = _19_}
end
local function setup_chat_buffer(canvas)
  canvas["set-option"](canvas, "buf", "buftype", "nofile")
  canvas["set-option"](canvas, "buf", "bufhidden", "hide")
  canvas["set-option"](canvas, "buf", "swapfile", false)
  return canvas["set-option"](canvas, "buf", "filetype", "eca-chat")
end
local function setup_chat_window(canvas)
  canvas["set-option"](canvas, "win", "number", false)
  canvas["set-option"](canvas, "win", "relativenumber", false)
  canvas["set-option"](canvas, "win", "signcolumn", "no")
  canvas["set-option"](canvas, "win", "foldcolumn", "0")
  canvas["set-option"](canvas, "win", "spell", false)
  canvas["set-option"](canvas, "win", "wrap", true)
  canvas["set-option"](canvas, "win", "linebreak", true)
  return canvas["set-option"](canvas, "win", "conceallevel", 2)
end
local function setup_edit_guard(api, buf_id, get_prompt_start_line)
  local internal_edit = false
  local function set_internal(bool)
    internal_edit = bool
    return nil
  end
  local function _20_(_, buf, changedtick, first_line, last_line, new_last_line)
    if not internal_edit then
      local prompt_start = get_prompt_start_line()
      if (first_line < prompt_start) then
        local function _21_()
          if api["buf-is-valid"](buf) then
            return vim.cmd("silent! undo")
          else
            return nil
          end
        end
        return api.schedule(_21_)
      else
        return nil
      end
    else
      return nil
    end
  end
  api["buf-attach"](buf_id, {on_lines = _20_})
  return set_internal
end
local function create_chat_ui(_25_)
  local api = _25_.api
  local on_submit = _25_["on-submit"]
  local on_approve = _25_["on-approve"]
  local on_reject = _25_["on-reject"]
  local on_stop = _25_["on-stop"]
  local on_new_chat = _25_["on-new-chat"]
  local on_select_tab = _25_["on-select-tab"]
  local on_context_add = _25_["on-context-add"]
  local opts = _25_.opts
  local ui_config = (opts.ui or {})
  local config = {width = (ui_config.width or 0.4), position = (ui_config.position or "right")}
  local canvas = nil
  local set_internal_edit = nil
  local widgets = {header = nil, messages = nil, prompt = nil, status = nil, tabs = nil}
  local function is_open_3f()
    return ((nil ~= canvas) and canvas["buf-valid?"](canvas) and canvas["win-valid?"](canvas))
  end
  local function get_prompt_start_line()
    local state = widgets.prompt["get-state"]()
    return (state["prompt-start-line"] or 0)
  end
  local function with_internal_edit(f)
    if set_internal_edit then
      set_internal_edit(true)
    else
    end
    f()
    if set_internal_edit then
      return set_internal_edit(false)
    else
      return nil
    end
  end
  local function render_all()
    local function _28_()
      widgets.header.render()
      widgets.messages.render()
      do
        local end_line = widgets.messages["get-end-line"]()
        widgets.prompt.render(end_line)
      end
      widgets.status.render()
      return widgets.tabs.render()
    end
    return with_internal_edit(_28_)
  end
  local function open()
    if not is_open_3f() then
      local buf_id = api["buf-create"]({scratch = true, listed = false})
      local win_width = math.floor((api["editor-width"]() * config.width))
      local win_id = api["win-open"](buf_id, {split = "right", width = win_width})
      canvas = build_canvas(api, buf_id, win_id)
      highlights.setup(canvas)
      setup_chat_buffer(canvas)
      setup_chat_window(canvas)
      widgets.header = header_bar_widget.create(canvas, {})
      widgets.messages = message_list_widget.create(canvas)
      widgets.prompt = prompt_area_widget.create(canvas)
      widgets.status = status_bar_widget.create(canvas, {})
      widgets.tabs = tab_bar_widget.create(canvas, {tabs = {{id = 1, title = "Chat 1"}}, ["active-id"] = 1})
      set_internal_edit = setup_edit_guard(api, buf_id, get_prompt_start_line)
      local function _29_()
        return canvas["set-lines"](canvas, 0, -1, {""})
      end
      with_internal_edit(_29_)
      return render_all()
    else
      return nil
    end
  end
  local function close()
    if is_open_3f() then
      return canvas["close-win"](canvas)
    else
      return nil
    end
  end
  local function toggle()
    if is_open_3f() then
      return close()
    else
      return open()
    end
  end
  local function append_message(msg)
    if is_open_3f() then
      local function _33_()
        widgets.messages["append-message"](msg)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_33_)
    else
      return nil
    end
  end
  local function update_message(id, content)
    if is_open_3f() then
      local function _35_()
        widgets.messages["update-message"](id, content)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_35_)
    else
      return nil
    end
  end
  local function clear_messages()
    if is_open_3f() then
      local function _37_()
        widgets.messages.clear()
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_37_)
    else
      return nil
    end
  end
  local function show_tool_call(tc)
    return nil
  end
  local function update_tool_call(id, status)
    return nil
  end
  local function show_approval(tc)
    return nil
  end
  local function update_model_info(info)
    if is_open_3f() then
      return widgets.header.update(info)
    else
      return nil
    end
  end
  local function update_usage(usage)
    if is_open_3f() then
      return widgets.status.update(usage)
    else
      return nil
    end
  end
  local function update_progress(progress)
    if is_open_3f() then
      return widgets.status.update({["init-progress"] = progress})
    else
      return nil
    end
  end
  local function add_context(ctx)
    if is_open_3f() then
      local function _42_()
        widgets.prompt["add-context"](ctx)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_42_)
    else
      return nil
    end
  end
  local function remove_context(name)
    if is_open_3f() then
      local function _44_()
        widgets.prompt["remove-context"](name)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_44_)
    else
      return nil
    end
  end
  local function add_chat_tab(tab)
    if is_open_3f() then
      widgets.tabs["add-tab"](tab)
      return widgets.tabs.render()
    else
      return nil
    end
  end
  local function remove_chat_tab(id)
    if is_open_3f() then
      widgets.tabs["remove-tab"](id)
      return widgets.tabs.render()
    else
      return nil
    end
  end
  local function select_chat_tab(id)
    if is_open_3f() then
      widgets.tabs["select-tab"](id)
      return widgets.tabs.render()
    else
      return nil
    end
  end
  local function get_prompt_text()
    if is_open_3f() then
      return widgets.prompt["get-text"]()
    else
      return nil
    end
  end
  local function submit_prompt()
    if is_open_3f() then
      local text = widgets.prompt["get-text"]()
      if (text and ("" ~= text)) then
        widgets.prompt["add-to-history"](text)
        local function _50_()
          return widgets.prompt.clear()
        end
        with_internal_edit(_50_)
        if on_submit then
          return on_submit(text)
        else
          return nil
        end
      else
        return nil
      end
    else
      return nil
    end
  end
  local function set_loading(bool)
    if is_open_3f() then
      local function _54_()
        return widgets.prompt["set-loading"](bool)
      end
      return with_internal_edit(_54_)
    else
      return nil
    end
  end
  return {open = open, close = close, toggle = toggle, ["is-open?"] = is_open_3f, ["append-message"] = append_message, ["update-message"] = update_message, ["clear-messages"] = clear_messages, ["show-tool-call"] = show_tool_call, ["update-tool-call"] = update_tool_call, ["show-approval"] = show_approval, ["update-model-info"] = update_model_info, ["update-usage"] = update_usage, ["update-progress"] = update_progress, ["add-context"] = add_context, ["remove-context"] = remove_context, ["add-chat-tab"] = add_chat_tab, ["remove-chat-tab"] = remove_chat_tab, ["select-chat-tab"] = select_chat_tab, ["get-prompt-text"] = get_prompt_text, ["submit-prompt"] = submit_prompt, ["set-loading"] = set_loading}
end
return {["create-chat-ui"] = create_chat_ui}
