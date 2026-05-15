-- [nfnl] fnl/eca/ui/builder.fnl
local nvim = vim.api
local highlights = require("eca.ui.highlights")
local header_bar_widget = require("eca.ui.widgets.header-bar")
local message_list_widget = require("eca.ui.widgets.message-list")
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
  local guard_ns = nil
  local function ensure_guard_ns()
    if (nil == guard_ns) then
      guard_ns = nvim.nvim_create_namespace("eca-edit-guard")
    else
    end
    return guard_ns
  end
  local function get_prefix(loading_3f)
    local prompt_prefix = require("eca.ui.components.prompt-prefix")
    return prompt_prefix.render({["loading?"] = loading_3f}).text
  end
  local function salvage_user_text(buf, prompt_start_line, prefix)
    local current_count = nvim.nvim_buf_line_count(buf)
    local start = math.min(prompt_start_line, current_count)
    local prompt_lines = nvim.nvim_buf_get_lines(buf, start, current_count, false)
    if (0 == #prompt_lines) then
      return {""}
    else
      local tbl_26_ = {}
      local i_27_ = 0
      for i, line in ipairs(prompt_lines) do
        local val_28_
        if (i == 1) then
          if vim.startswith(line, prefix) then
            val_28_ = string.sub(line, (#prefix + 1))
          else
            val_28_ = line:gsub("^>%s*", "")
          end
        else
          val_28_ = line
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      return tbl_26_
    end
  end
  local function restore_with_user_text(buf, prefix, user_lines)
    internal_edit = true
    render_all_fn()
    do
      local new_count = nvim.nvim_buf_line_count(buf)
      local new_last_idx = (new_count - 1)
      local restored_lines
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for i, line in ipairs(user_lines) do
          local val_28_
          if (i == 1) then
            val_28_ = (prefix .. line)
          else
            val_28_ = line
          end
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        restored_lines = tbl_26_
      end
      if (#restored_lines > 0) then
        nvim.nvim_buf_set_lines(buf, new_last_idx, new_count, false, restored_lines)
        local ns = ensure_guard_ns()
        nvim.nvim_buf_set_extmark(buf, ns, new_last_idx, 0, {end_col = #prefix, hl_group = "EcaPromptPrefix"})
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
      local _let_14_ = get_prompt_state()
      local prompt_start_line = _let_14_["prompt-start-line"]
      local loading_3f = _let_14_["loading?"]
      local prefix = get_prefix(loading_3f)
      local function _15_()
        if nvim.nvim_buf_is_valid(buf) then
          local current_count = nvim.nvim_buf_line_count(buf)
          local prompt_idx = math.min(prompt_start_line, (current_count - 1))
          local prompt_lines = nvim.nvim_buf_get_lines(buf, prompt_idx, (prompt_idx + 1), false)
          local prompt_line_text = (prompt_lines[1] or "")
          local damaged_3f = ((first_line < prompt_start_line) or not vim.startswith(prompt_line_text, prefix))
          if damaged_3f then
            local user_lines = salvage_user_text(buf, prompt_start_line, prefix)
            return restore_with_user_text(buf, prefix, user_lines)
          else
            return nil
          end
        else
          return nil
        end
      end
      return vim.schedule(_15_)
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
local function create_chat_ui(_19_)
  local on_submit = _19_["on-submit"]
  local on_stop = _19_["on-stop"]
  local opts = _19_.opts
  local ui_config = (opts.ui or {})
  local config = {width = (ui_config.width or 0.4), position = (ui_config.position or "right"), keymaps = (opts.keymaps or {})}
  local state = {["header-items"] = {}, ["footer-items"] = {}, welcome = nil}
  local buf_id = nil
  local win_id = nil
  local guard = nil
  local widgets = {header = nil, messages = nil, prompt = nil, footer = nil}
  local function is_open_3f()
    return ((nil ~= buf_id) and nvim.nvim_buf_is_valid(buf_id) and (nil ~= win_id) and nvim.nvim_win_is_valid(win_id))
  end
  local function with_internal_edit(f)
    local saved_cursor
    if (win_id and nvim.nvim_win_is_valid(win_id)) then
      saved_cursor = nvim.nvim_win_get_cursor(win_id)
    else
      saved_cursor = nil
    end
    if guard then
      guard["set-internal"](true)
    else
    end
    f()
    if guard then
      guard["set-internal"](false)
      guard["update-expected-count"]()
    else
    end
    if (saved_cursor and win_id and nvim.nvim_win_is_valid(win_id)) then
      local total = nvim.nvim_buf_line_count(buf_id)
      local line = math.min(saved_cursor[1], total)
      local col = saved_cursor[2]
      return pcall(nvim.nvim_win_set_cursor, win_id, {line, col})
    else
      return nil
    end
  end
  local function focus_prompt()
    if (win_id and nvim.nvim_win_is_valid(win_id)) then
      local total = nvim.nvim_buf_line_count(buf_id)
      local prompt_state = widgets.prompt["get-state"]()
      local prompt_line = (prompt_state["prompt-start-line"] or (total - 1))
      return nvim.nvim_win_set_cursor(win_id, {(prompt_line + 1), 2})
    else
      return nil
    end
  end
  local function render_all()
    local function _25_()
      do
        local header_lines = widgets.header.render()
        widgets.messages["set-start-line"](header_lines)
        widgets.messages.render()
        local end_line = widgets.messages["get-end-line"]()
        widgets.prompt.render(end_line)
      end
      if widgets.footer then
        return widgets.footer.render()
      else
        return nil
      end
    end
    return with_internal_edit(_25_)
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
  local function submit_prompt()
    if is_open_3f() then
      local prompt_state = widgets.prompt["get-state"]()
      if prompt_state["loading?"] then
        if on_stop then
          return on_stop()
        else
          return nil
        end
      else
        local text = widgets.prompt["get-text"]()
        if (text and ("" ~= text)) then
          widgets.prompt["add-to-history"](text)
          local function _29_()
            return widgets.prompt.clear()
          end
          with_internal_edit(_29_)
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
      local function _34_()
        local s = widgets.prompt["get-state"]()
        s["prompt-start-line"] = (s["prompt-start-line"] + 1)
        return nil
      end
      widgets.messages = message_list_widget.create(buf_id, {["wrap-write"] = with_internal_edit, ["on-line-inserted"] = _34_})
      if state.welcome then
        widgets.messages["set-welcome"]({lines = {state.welcome, ""}, highlights = {{["line-idx"] = 0, ["hl-group"] = "EcaWelcome", ["col-start"] = 0, ["col-end"] = #state.welcome}}})
      else
      end
      widgets.prompt = prompt_area_widget.create(buf_id, {["wrap-write"] = with_internal_edit})
      widgets.footer = footer_bar_widget.create(buf_id, win_id, state["footer-items"])
      for _, km in ipairs(config.keymaps) do
        vim.keymap.set(km.mode, km.lhs, km.rhs, {buffer = buf_id, noremap = true, silent = true})
      end
      nvim.nvim_buf_set_lines(buf_id, 0, -1, false, {""})
      render_all()
      focus_prompt()
      local function _36_()
        local s = widgets.prompt["get-state"]()
        return {["prompt-start-line"] = (s["prompt-start-line"] or 0), ["loading?"] = s["loading?"]}
      end
      guard = setup_edit_guard(buf_id, render_all, _36_, focus_prompt)
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
      local function _39_()
        widgets.messages["append-message"](msg)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      with_internal_edit(_39_)
      return focus_prompt()
    else
      return nil
    end
  end
  local function update_message(id, content)
    if is_open_3f() then
      local function _41_()
        widgets.messages["update-message"](id, content)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_41_)
    else
      return nil
    end
  end
  local function finish_streaming(id)
    if is_open_3f() then
      local function _43_()
        widgets.messages["finish-streaming"](id)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_43_)
    else
      return nil
    end
  end
  local function clear_messages()
    if is_open_3f() then
      local function _45_()
        widgets.messages.clear()
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_45_)
    else
      return nil
    end
  end
  local function update_header(new_items)
    state["header-items"] = new_items
    if is_open_3f() then
      local function _47_()
        return widgets.header.update(new_items)
      end
      return with_internal_edit(_47_)
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
      local function _51_()
        return widgets.header.update(state["header-items"])
      end
      return with_internal_edit(_51_)
    else
      return nil
    end
  end
  local function update_footer(new_items)
    state["footer-items"] = new_items
    if is_open_3f() then
      local function _53_()
        return widgets.footer.update(new_items)
      end
      return with_internal_edit(_53_)
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
      local function _57_()
        return widgets.footer.update(state["footer-items"])
      end
      return with_internal_edit(_57_)
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
        local function _59_()
          return render_all()
        end
        return with_internal_edit(_59_)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function set_status(text)
    if is_open_3f() then
      local function _62_()
        widgets.prompt["set-status"](text)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_62_)
    else
      return nil
    end
  end
  local function set_loading(bool)
    if is_open_3f() then
      local function _64_()
        widgets.prompt["set-loading"](bool)
        local end_line = widgets.messages["get-end-line"]()
        return widgets.prompt.render(end_line)
      end
      return with_internal_edit(_64_)
    else
      return nil
    end
  end
  return {open = open, close = close, toggle = toggle, ["is-open?"] = is_open_3f, ["get-buf-id"] = get_buf_id, ["append-message"] = append_message, ["update-message"] = update_message, ["finish-streaming"] = finish_streaming, ["clear-messages"] = clear_messages, ["update-header"] = update_header, ["update-header-item"] = update_header_item, ["update-footer"] = update_footer, ["update-footer-item"] = update_footer_item, ["set-welcome"] = set_welcome, ["submit-prompt"] = submit_prompt, ["set-status"] = set_status, ["set-loading"] = set_loading}
end
return {["create-chat-ui"] = create_chat_ui}
