-- [nfnl] fnl/eca/ui/builder.fnl
local nvim = vim.api
local highlights = require("eca.ui.highlights")
local header_bar_widget = require("eca.ui.widgets.header-bar")
local message_list_widget = require("eca.ui.widgets.message-list")
local context_area_widget = require("eca.ui.widgets.context-area")
local steering_area_widget = require("eca.ui.widgets.steering-area")
local prompt_area_widget = require("eca.ui.widgets.prompt-area")
local footer_bar_widget = require("eca.ui.widgets.footer-bar")
local function setup_chat_buffer(buf)
  nvim.nvim_buf_set_name(buf, "ECA Chat")
  nvim.nvim_set_option_value("buftype", "nofile", {buf = buf})
  nvim.nvim_set_option_value("bufhidden", "hide", {buf = buf})
  nvim.nvim_set_option_value("swapfile", false, {buf = buf})
  return nvim.nvim_set_option_value("filetype", "eca-chat", {buf = buf})
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
        local function _6_()
          if nvim.nvim_buf_is_valid(buf) then
            local user_lines = salvage_user_text(buf, prompt_line)
            return restore_with_user_text(buf, user_lines)
          else
            return nil
          end
        end
        return vim.schedule(_6_)
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
local function create_chat_ui(_10_)
  local on_submit = _10_["on-submit"]
  local on_stop = _10_["on-stop"]
  local opts = _10_.opts
  local ui_config = (opts.ui or {})
  local config = {width = (ui_config.width or 0.4), position = (ui_config.position or "right"), keymaps = (opts.keymaps or {})}
  local state = {["header-items"] = {}, ["footer-items"] = {}, welcome = nil, ["steering-queue"] = {}, ["stop-line"] = nil, ["stopped-msg-id"] = nil}
  local buf_id = nil
  local win_id = nil
  local guard = nil
  local widgets = {header = nil, messages = nil, context = nil, steering = nil, prompt = nil, footer = nil}
  local function is_open_3f()
    return ((nil ~= buf_id) and nvim.nvim_buf_is_valid(buf_id) and (nil ~= win_id) and nvim.nvim_win_is_valid(win_id))
  end
  local internal_edit_depth = 0
  local function with_internal_edit(f)
    internal_edit_depth = (internal_edit_depth + 1)
    if (guard and (internal_edit_depth == 1)) then
      guard["set-internal"](true)
    else
    end
    f()
    internal_edit_depth = (internal_edit_depth - 1)
    if (guard and (internal_edit_depth == 0)) then
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
    local has_ctx_3f = widgets.context["has-items?"]()
    local has_steering_3f = widgets.steering["has-items?"]()
    local is_loading_3f = widgets.prompt["get-state"]()["loading?"]
    local prompt_text_lines = vim.split((live_text or ""), "\n", {plain = true})
    local all_lines = {sep}
    if has_ctx_3f then
      local ctx_items = widgets.context["get-state"]()
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
    if has_steering_3f then
      table.insert(all_lines, "-")
    else
    end
    if is_loading_3f then
      table.insert(all_lines, "stop")
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
    local offset = 1
    local ctx_line
    if has_ctx_3f then
      local l = (msg_end + offset)
      offset = (offset + 1)
      ctx_line = l
    else
      ctx_line = nil
    end
    local steering_line
    if has_steering_3f then
      local l = (msg_end + offset)
      offset = (offset + 1)
      steering_line = l
    else
      steering_line = nil
    end
    local stop_line_pos
    if is_loading_3f then
      local l = (msg_end + offset)
      offset = (offset + 1)
      stop_line_pos = l
    else
      stop_line_pos = nil
    end
    local prompt_start = (msg_end + offset)
    state["stop-line"] = stop_line_pos
    widgets.prompt["set-text-internal"]((live_text or ""))
    do
      local ns = nvim.nvim_create_namespace("eca-separator")
      nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
      pcall(nvim.nvim_buf_set_extmark, buf_id, ns, msg_end, 0, {end_col = #sep, hl_group = "EcaSeparator"})
    end
    widgets.prompt["set-status-anchor-line"](msg_end)
    if ctx_line then
      widgets.context["render-highlights"](ctx_line)
    else
    end
    if steering_line then
      widgets.steering["render-highlights"](steering_line)
    else
    end
    if stop_line_pos then
      local ns = nvim.nvim_create_namespace("eca-stop-line")
      nvim.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
      nvim.nvim_buf_set_extmark(buf_id, ns, stop_line_pos, 0, {virt_text = {{"\226\143\179 ", "EcaSpinner"}}, virt_text_pos = "inline"})
      nvim.nvim_buf_set_extmark(buf_id, ns, stop_line_pos, 0, {end_col = 4, hl_group = "EcaStopLabel"})
    else
    end
    return widgets.prompt["render-highlights"](prompt_start)
  end
  local function render_all()
    local function _25_()
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
  local function cancel_steering()
    if (#state["steering-queue"] > 0) then
      state["steering-queue"] = {}
      if is_open_3f() then
        local function _28_()
          widgets.steering.clear()
          return render_prompt_area()
        end
        return with_internal_edit(_28_)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function stop()
    cancel_steering()
    do
      local msg_state = widgets.messages["get-state"]()
      if msg_state["streaming-id"] then
        state["stopped-msg-id"] = msg_state["streaming-id"]
        local function _31_()
          widgets.messages["abort-streaming"](msg_state["streaming-id"])
          return render_prompt_area()
        end
        with_internal_edit(_31_)
      else
      end
    end
    if on_stop then
      return on_stop()
    else
      return nil
    end
  end
  local function is_on_stop_line_3f()
    local and_34_ = state["stop-line"]
    if and_34_ then
      local cursor = nvim.nvim_win_get_cursor(0)
      local row = cursor[1]
      and_34_ = (row == (state["stop-line"] + 1))
    end
    return and_34_
  end
  local function submit_prompt()
    if is_open_3f() then
      if widgets.steering["is-on-steering-line?"]() then
        cancel_steering()
        return focus_prompt()
      elseif is_on_stop_line_3f() then
        return stop()
      else
        local prompt_state = widgets.prompt["get-state"]()
        local text = widgets.prompt["get-text"]()
        if prompt_state["loading?"] then
          if (text and ("" ~= text)) then
            table.insert(state["steering-queue"], text)
            widgets.prompt["add-to-history"](text)
            local function _36_()
              widgets.prompt.clear()
              widgets.steering["set-items"](state["steering-queue"])
              return render_prompt_area()
            end
            with_internal_edit(_36_)
            return focus_prompt()
          else
            return nil
          end
        else
          if (text and ("" ~= text)) then
            widgets.prompt["add-to-history"](text)
            local function _38_()
              return widgets.prompt.clear()
            end
            with_internal_edit(_38_)
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
      local function _44_()
        local s = widgets.prompt["get-state"]()
        local st = widgets.steering["get-state"]()
        s["prompt-start-line"] = (s["prompt-start-line"] + 1)
        s["status-anchor-line"] = (s["status-anchor-line"] + 1)
        if (st["start-line"] > 0) then
          st["start-line"] = (st["start-line"] + 1)
          st["end-line"] = (st["end-line"] + 1)
        else
        end
        if state["stop-line"] then
          state["stop-line"] = (state["stop-line"] + 1)
          return nil
        else
          return nil
        end
      end
      widgets.messages = message_list_widget.create(buf_id, {["wrap-write"] = with_internal_edit, ["on-line-inserted"] = _44_})
      if state.welcome then
        widgets.messages["set-welcome"]({lines = {state.welcome, ""}, highlights = {{["line-idx"] = 0, ["hl-group"] = "EcaWelcome", ["col-start"] = 0, ["col-end"] = #state.welcome}}})
      else
      end
      widgets.context = context_area_widget.create(buf_id)
      widgets.steering = steering_area_widget.create(buf_id)
      widgets.prompt = prompt_area_widget.create(buf_id, {["wrap-write"] = with_internal_edit})
      widgets.footer = footer_bar_widget.create(buf_id, win_id, state["footer-items"])
      for _, km in ipairs(config.keymaps) do
        vim.keymap.set(km.mode, km.lhs, km.rhs, {buffer = buf_id, noremap = true, silent = true})
      end
      nvim.nvim_buf_set_lines(buf_id, 0, -1, false, {""})
      render_all()
      focus_prompt()
      local function _48_()
        local s = widgets.prompt["get-state"]()
        return {["prompt-start-line"] = (s["prompt-start-line"] or 0), ["loading?"] = s["loading?"]}
      end
      guard = setup_edit_guard(buf_id, render_all, _48_, focus_prompt)
      local function _49_()
        if is_open_3f() then
          local function _50_()
            return render_prompt_area()
          end
          with_internal_edit(_50_)
          return focus_prompt()
        else
          return nil
        end
      end
      return nvim.nvim_create_autocmd("WinResized", {callback = _49_})
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
      if msg["streaming?"] then
        state["stopped-msg-id"] = nil
      else
      end
      local function _55_()
        widgets.messages["append-message"](msg)
        return render_prompt_area()
      end
      with_internal_edit(_55_)
      return focus_prompt()
    else
      return nil
    end
  end
  local function update_message(id, content)
    if (is_open_3f() and (id ~= state["stopped-msg-id"])) then
      local msg_state = widgets.messages["get-state"]()
      local function _57_()
        widgets.messages["update-message"](id, content)
        if (id ~= msg_state["streaming-id"]) then
          return render_prompt_area()
        else
          return nil
        end
      end
      return with_internal_edit(_57_)
    else
      return nil
    end
  end
  local function finish_streaming(id)
    if (is_open_3f() and (id ~= state["stopped-msg-id"])) then
      local function _60_()
        widgets.messages["finish-streaming"](id)
        return render_prompt_area()
      end
      return with_internal_edit(_60_)
    else
      return nil
    end
  end
  local function clear_messages()
    if is_open_3f() then
      local function _62_()
        widgets.messages.clear()
        return render_prompt_area()
      end
      return with_internal_edit(_62_)
    else
      return nil
    end
  end
  local function update_header(new_items)
    state["header-items"] = new_items
    if is_open_3f() then
      local function _64_()
        return widgets.header.update(new_items)
      end
      return with_internal_edit(_64_)
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
      local function _68_()
        return widgets.header.update(state["header-items"])
      end
      return with_internal_edit(_68_)
    else
      return nil
    end
  end
  local function update_footer(new_items)
    state["footer-items"] = new_items
    if is_open_3f() then
      local function _70_()
        return widgets.footer.update(new_items)
      end
      return with_internal_edit(_70_)
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
      local function _74_()
        return widgets.footer.update(state["footer-items"])
      end
      return with_internal_edit(_74_)
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
        local function _76_()
          return render_all()
        end
        return with_internal_edit(_76_)
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
      local function _80_()
        widgets.context.add(ctx)
        return render_prompt_area()
      end
      with_internal_edit(_80_)
      return focus_prompt()
    else
      return nil
    end
  end
  local function remove_context(name)
    if is_open_3f() then
      local function _82_()
        widgets.context.remove(name)
        return render_prompt_area()
      end
      return with_internal_edit(_82_)
    else
      return nil
    end
  end
  local function set_loading(bool)
    if is_open_3f() then
      widgets.prompt["set-loading"](bool)
      local function _84_()
        return render_prompt_area()
      end
      with_internal_edit(_84_)
      focus_prompt()
      if (not bool and (#state["steering-queue"] > 0)) then
        local combined = table.concat(state["steering-queue"], "\n")
        state["steering-queue"] = {}
        local function _85_()
          widgets.steering.clear()
          return render_prompt_area()
        end
        with_internal_edit(_85_)
        if on_submit then
          return on_submit(combined)
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
