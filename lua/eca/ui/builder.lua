-- [nfnl] fnl/eca/ui/builder.fnl
local nvim = vim.api
local highlights = require("eca.ui.highlights")
local header_bar_widget = require("eca.ui.widgets.header-bar")
local message_list_widget = require("eca.ui.widgets.message-list")
local context_area_widget = require("eca.ui.widgets.context-area")
local prompt_area_widget = require("eca.ui.widgets.prompt-area")
local footer_bar_widget = require("eca.ui.widgets.footer-bar")
local function disable_statusline_plugins()
  local ok, lualine = pcall(require, "lualine")
  if ok then
    local config = lualine.get_config()
    local disabled = (config.options.disabled_filetypes or {})
    if not disabled.statusline then
      disabled["statusline"] = {}
    else
    end
    local found = false
    for _, ft in ipairs(disabled.statusline) do
      if (ft == "eca-chat") then
        found = true
      else
      end
    end
    if not found then
      table.insert(disabled.statusline, "eca-chat")
    else
    end
    config.options["disabled_filetypes"] = disabled
    return lualine.setup(config)
  else
    return nil
  end
end
local function setup_chat_buffer(buf)
  nvim.nvim_buf_set_name(buf, "ECA Chat")
  nvim.nvim_set_option_value("buftype", "nofile", {buf = buf})
  nvim.nvim_set_option_value("bufhidden", "hide", {buf = buf})
  nvim.nvim_set_option_value("swapfile", false, {buf = buf})
  nvim.nvim_set_option_value("filetype", "eca-chat", {buf = buf})
  return disable_statusline_plugins()
end
local function setup_chat_window(win)
  nvim.nvim_set_option_value("number", false, {win = win})
  nvim.nvim_set_option_value("relativenumber", false, {win = win})
  nvim.nvim_set_option_value("signcolumn", "no", {win = win})
  nvim.nvim_set_option_value("foldcolumn", "0", {win = win})
  nvim.nvim_set_option_value("numberwidth", 1, {win = win})
  nvim.nvim_set_option_value("statuscolumn", "", {win = win})
  nvim.nvim_set_option_value("spell", false, {win = win})
  nvim.nvim_set_option_value("list", false, {win = win})
  nvim.nvim_set_option_value("wrap", true, {win = win})
  nvim.nvim_set_option_value("linebreak", true, {win = win})
  return nvim.nvim_set_option_value("conceallevel", 2, {win = win})
end
local function setup_edit_guard(buf_id, render_all_fn, get_prompt_state, focus_prompt_fn)
  local internal_edit = false
  local function salvage_user_text(buf, prompt_line)
    local current_count = nvim.nvim_buf_line_count(buf)
    local idx = math.min(prompt_line, (current_count - 1))
    local lines = nvim.nvim_buf_get_lines(buf, idx, (idx + 1), false)
    local last_line = (lines[1] or "")
    if vim.startswith(last_line, "> ") then
      return {string.sub(last_line, 3)}
    else
      return {""}
    end
  end
  local function restore_with_user_text(buf, user_lines)
    internal_edit = true
    render_all_fn()
    do
      local new_count = nvim.nvim_buf_line_count(buf)
      local new_last_idx = (new_count - 1)
      local restored
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for i, line in ipairs(user_lines) do
          local val_28_
          if (i == 1) then
            val_28_ = ("> " .. line)
          else
            val_28_ = line
          end
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        restored = tbl_26_
      end
      if (#restored > 0) then
        nvim.nvim_buf_set_lines(buf, new_last_idx, new_count, false, restored)
        local ns = nvim.nvim_create_namespace("eca-prompt-restore")
        nvim.nvim_buf_set_extmark(buf, ns, new_last_idx, 0, {end_col = 2, hl_group = "EcaPromptPrefix"})
      else
      end
    end
    internal_edit = false
    if focus_prompt_fn then
      return focus_prompt_fn()
    else
      return nil
    end
  end
  local function on_lines_handler(_, buf, changedtick, first_line, last_line, new_last_line)
    if not internal_edit then
      local prompt_state = get_prompt_state()
      local prompt_line = (prompt_state["prompt-start-line"] or 0)
      local lines_deleted_3f = (last_line > new_last_line)
      local damaged_3f = ((first_line < prompt_line) or ((first_line <= prompt_line) and lines_deleted_3f))
      if damaged_3f then
        local function _10_()
          if nvim.nvim_buf_is_valid(buf) then
            local user_lines = salvage_user_text(buf, prompt_line)
            return restore_with_user_text(buf, user_lines)
          else
            return nil
          end
        end
        return vim.schedule(_10_)
      else
        return nil
      end
    else
      return nil
    end
  end
  nvim.nvim_buf_attach(buf_id, false, {on_lines = on_lines_handler})
  local function set_internal(bool)
    internal_edit = bool
    return nil
  end
  local function update_expected_count()
    return nil
  end
  return {["set-internal"] = set_internal, ["update-expected-count"] = update_expected_count}
end
local function create_chat_ui(_14_)
  local on_submit = _14_["on-submit"]
  local on_stop = _14_["on-stop"]
  local opts = _14_.opts
  local ui_config = (opts.ui or {})
  local config = {width = (ui_config.width or 0.4), position = (ui_config.position or "right"), keymaps = (opts.keymaps or {})}
  local state = {["header-items"] = {}, ["footer-items"] = {}, welcome = nil, ["queued-prompt"] = nil}
  local buf_id = nil
  local win_id = nil
  local guard = nil
  local widgets = {header = nil, messages = nil, context = nil, prompt = nil, footer = nil}
  local function is_open_3f()
    return ((nil ~= buf_id) and nvim.nvim_buf_is_valid(buf_id) and (nil ~= win_id) and nvim.nvim_win_is_valid(win_id))
  end
  local function with_internal_edit(f)
    if guard then
      guard["set-internal"](true)
    else
    end
    f()
    if guard then
      guard["set-internal"](false)
      return guard["update-expected-count"]()
    else
      return nil
    end
  end
  local function focus_prompt()
    if (win_id and nvim.nvim_win_is_valid(win_id)) then
      local total = nvim.nvim_buf_line_count(buf_id)
      local prompt_state = widgets.prompt["get-state"]()
      local prompt_line = (prompt_state["prompt-start-line"] or (total - 1))
      local line_text = (nvim.nvim_buf_get_lines(buf_id, prompt_line, (prompt_line + 1), false)[1] or "> ")
      local col = #line_text
      return nvim.nvim_win_set_cursor(win_id, {(prompt_line + 1), col})
    else
      return nil
    end
  end
  local function make_separator()
    local win = vim.fn.bufwinid(buf_id)
    local width
    if (win and (win ~= -1)) then
      width = nvim.nvim_win_get_width(win)
    else
      width = 40
    end
    return string.rep("\226\148\128", width)
  end
  local function render_prompt_area()
    local msg_end = widgets.messages["get-end-line"]()
    local live_text = widgets.prompt["save-live-text"]()
    local sep = make_separator()
    local ctx_items = widgets.context["get-state"]()
    local has_ctx_3f = widgets.context["has-items?"]()
    local prompt_text_lines = vim.split((live_text or ""), "\n", {plain = true})
    local all_lines = {sep}
    if has_ctx_3f then
      local parts
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _, item in ipairs(ctx_items.items) do
          local val_28_ = item.text
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        parts = tbl_26_
      end
      table.insert(all_lines, table.concat(parts, " "))
    else
    end
    do
      local idle_prefix = "> "
      table.insert(all_lines, (idle_prefix .. (prompt_text_lines[1] or "")))
      for i = 2, #prompt_text_lines do
        table.insert(all_lines, prompt_text_lines[i])
      end
    end
    nvim.nvim_buf_set_lines(buf_id, msg_end, -1, false, all_lines)
    local prompt_start
    local _21_
    if has_ctx_3f then
      _21_ = 2
    else
      _21_ = 1
    end
    prompt_start = (msg_end + _21_)
    widgets.prompt["set-text-internal"]((live_text or ""))
    do
      local ns = nvim.nvim_create_namespace("eca-separator")
      nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
      pcall(nvim.nvim_buf_set_extmark, buf_id, ns, msg_end, 0, {end_col = #sep, hl_group = "EcaSeparator"})
    end
    widgets.prompt["set-status-anchor-line"](msg_end)
    if has_ctx_3f then
      widgets.context["render-highlights"]((msg_end + 1))
    else
    end
    return widgets.prompt["render-highlights"](prompt_start)
  end
  local function render_all()
    local function _24_()
      do
        local header_lines = widgets.header.render()
        widgets.messages["set-start-line"](header_lines)
        widgets.messages.render()
        render_prompt_area()
      end
      if widgets.footer then
        return widgets.footer.render()
      else
        return nil
      end
    end
    return with_internal_edit(_24_)
  end
  local function close()
    if is_open_3f() then
      nvim.nvim_win_close(win_id, true)
      win_id = nil
      return nil
    else
      return nil
    end
  end
  local function cancel_steering()
    if state["queued-prompt"] then
      state["queued-prompt"] = nil
      if is_open_3f() then
        local function _27_()
          widgets.prompt["set-steering"](nil)
          return render_prompt_area()
        end
        return with_internal_edit(_27_)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function stop()
    cancel_steering()
    if on_stop then
      return on_stop()
    else
      return nil
    end
  end
  local function submit_prompt()
    if is_open_3f() then
      local prompt_state = widgets.prompt["get-state"]()
      local text = widgets.prompt["get-text"]()
      if prompt_state["loading?"] then
        if (text and ("" ~= text)) then
          state["queued-prompt"] = text
          widgets.prompt["add-to-history"](text)
          local function _31_()
            widgets.prompt.clear()
            widgets.prompt["set-steering"](text)
            return render_prompt_area()
          end
          with_internal_edit(_31_)
          return focus_prompt()
        else
          return nil
        end
      else
        if (text and ("" ~= text)) then
          widgets.prompt["add-to-history"](text)
          local function _33_()
            return widgets.prompt.clear()
          end
          with_internal_edit(_33_)
          focus_prompt()
          if on_submit then
            return on_submit(text)
          else
            return nil
          end
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  local function open()
    if not is_open_3f() then
      buf_id = nvim.nvim_create_buf(false, true)
      do
        local width = math.floor((vim.o.columns * config.width))
        win_id = nvim.nvim_open_win(buf_id, true, {split = "right", width = width})
      end
      highlights.setup()
      setup_chat_buffer(buf_id)
      setup_chat_window(win_id)
      widgets.header = header_bar_widget.create(buf_id, win_id, state["header-items"])
      local function _38_()
        local s = widgets.prompt["get-state"]()
        s["prompt-start-line"] = (s["prompt-start-line"] + 1)
        return nil
      end
      widgets.messages = message_list_widget.create(buf_id, {["wrap-write"] = with_internal_edit, ["on-line-inserted"] = _38_})
      if state.welcome then
        widgets.messages["set-welcome"]({lines = {state.welcome, ""}, highlights = {{["line-idx"] = 0, ["hl-group"] = "EcaWelcome", ["col-start"] = 0, ["col-end"] = #state.welcome}}})
      else
      end
      widgets.context = context_area_widget.create(buf_id)
      widgets.prompt = prompt_area_widget.create(buf_id, {["wrap-write"] = with_internal_edit})
      widgets.footer = footer_bar_widget.create(buf_id, win_id, state["footer-items"])
      for _, km in ipairs(config.keymaps) do
        vim.keymap.set(km.mode, km.lhs, km.rhs, {buffer = buf_id, noremap = true, silent = true})
      end
      nvim.nvim_buf_set_lines(buf_id, 0, -1, false, {""})
      render_all()
      focus_prompt()
      local function _40_()
        local s = widgets.prompt["get-state"]()
        return {["prompt-start-line"] = (s["prompt-start-line"] or 0), ["loading?"] = s["loading?"]}
      end
      guard = setup_edit_guard(buf_id, render_all, _40_, focus_prompt)
      return nil
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
  local function get_buf_id()
    return buf_id
  end
  local function append_message(msg)
    if is_open_3f() then
      local function _43_()
        widgets.messages["append-message"](msg)
        return render_prompt_area()
      end
      with_internal_edit(_43_)
      return focus_prompt()
    else
      return nil
    end
  end
  local function update_message(id, content)
    if is_open_3f() then
      local function _45_()
        widgets.messages["update-message"](id, content)
        return render_prompt_area()
      end
      return with_internal_edit(_45_)
    else
      return nil
    end
  end
  local function finish_streaming(id)
    if is_open_3f() then
      local function _47_()
        widgets.messages["finish-streaming"](id)
        return render_prompt_area()
      end
      return with_internal_edit(_47_)
    else
      return nil
    end
  end
  local function clear_messages()
    if is_open_3f() then
      local function _49_()
        widgets.messages.clear()
        return render_prompt_area()
      end
      return with_internal_edit(_49_)
    else
      return nil
    end
  end
  local function update_header(new_items)
    state["header-items"] = new_items
    if is_open_3f() then
      local function _51_()
        return widgets.header.update(new_items)
      end
      return with_internal_edit(_51_)
    else
      return nil
    end
  end
  local function update_header_item(title, new_value)
    local found = false
    for _, item in ipairs(state["header-items"]) do
      if (item.title == title) then
        item["value"] = new_value
        found = true
      else
      end
    end
    if not found then
      table.insert(state["header-items"], {title = title, value = new_value})
    else
    end
    if is_open_3f() then
      local function _55_()
        return widgets.header.update(state["header-items"])
      end
      return with_internal_edit(_55_)
    else
      return nil
    end
  end
  local function update_footer(new_items)
    state["footer-items"] = new_items
    if is_open_3f() then
      local function _57_()
        return widgets.footer.update(new_items)
      end
      return with_internal_edit(_57_)
    else
      return nil
    end
  end
  local function update_footer_item(title, new_value)
    local found = false
    for _, item in ipairs(state["footer-items"]) do
      if (item.title == title) then
        item["value"] = new_value
        found = true
      else
      end
    end
    if not found then
      table.insert(state["footer-items"], {title = title, value = new_value})
    else
    end
    if is_open_3f() then
      local function _61_()
        return widgets.footer.update(state["footer-items"])
      end
      return with_internal_edit(_61_)
    else
      return nil
    end
  end
  local function set_welcome(text)
    state.welcome = text
    if is_open_3f() then
      widgets.messages["set-welcome"]({lines = {text, ""}, highlights = {{["line-idx"] = 0, ["hl-group"] = "EcaWelcome", ["col-start"] = 0, ["col-end"] = #text}}})
      local msg_state = widgets.messages["get-state"]()
      if (0 == #msg_state.messages) then
        local function _63_()
          return render_all()
        end
        return with_internal_edit(_63_)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function set_status(text)
    if is_open_3f() then
      return widgets.prompt["set-status"](text)
    else
      return nil
    end
  end
  local function add_context(ctx)
    if is_open_3f() then
      local function _67_()
        widgets.context.add(ctx)
        return render_prompt_area()
      end
      with_internal_edit(_67_)
      return focus_prompt()
    else
      return nil
    end
  end
  local function remove_context(name)
    if is_open_3f() then
      local function _69_()
        widgets.context.remove(name)
        return render_prompt_area()
      end
      return with_internal_edit(_69_)
    else
      return nil
    end
  end
  local function set_loading(bool)
    if is_open_3f() then
      widgets.prompt["set-loading"](bool)
      focus_prompt()
      if (not bool and state["queued-prompt"]) then
        local queued = state["queued-prompt"]
        state["queued-prompt"] = nil
        local function _71_()
          widgets.prompt["set-steering"](nil)
          return render_prompt_area()
        end
        with_internal_edit(_71_)
        if on_submit then
          return on_submit(queued)
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
  return {open = open, close = close, toggle = toggle, ["is-open?"] = is_open_3f, ["get-buf-id"] = get_buf_id, ["append-message"] = append_message, ["update-message"] = update_message, ["finish-streaming"] = finish_streaming, ["clear-messages"] = clear_messages, ["update-header"] = update_header, ["update-header-item"] = update_header_item, ["update-footer"] = update_footer, ["update-footer-item"] = update_footer_item, ["set-welcome"] = set_welcome, ["submit-prompt"] = submit_prompt, stop = stop, ["cancel-steering"] = cancel_steering, ["set-status"] = set_status, ["set-loading"] = set_loading, ["add-context"] = add_context, ["remove-context"] = remove_context}
end
return {["create-chat-ui"] = create_chat_ui}
