-- [nfnl] fnl/eca/api.fnl
local nvim = vim.api
local function buf_set_lines(buf, start, _end, lines)
  return nvim.nvim_buf_set_lines(buf, start, _end, false, lines)
end
local function buf_get_lines(buf, start, _end)
  return nvim.nvim_buf_get_lines(buf, start, _end, false)
end
local function buf_line_count(buf)
  return nvim.nvim_buf_line_count(buf)
end
local function buf_is_valid(buf)
  return ((nil ~= buf) and nvim.nvim_buf_is_valid(buf))
end
local function buf_create(opts)
  local o = (opts or {})
  local _1_
  if (nil ~= o.listed) then
    _1_ = o.listed
  else
    _1_ = false
  end
  local function _3_()
    if (nil ~= o.scratch) then
      return o.scratch
    else
      return true
    end
  end
  return nvim.nvim_create_buf(_1_, _3_())
end
local function buf_set_keymap(buf, mode, lhs, rhs, opts)
  return nvim.nvim_buf_set_keymap(buf, mode, lhs, rhs, (opts or {}))
end
local function win_open(buf, opts)
  return nvim.nvim_open_win(buf, true, (opts or {}))
end
local function win_close(win)
  if (win and nvim.nvim_win_is_valid(win)) then
    return nvim.nvim_win_close(win, true)
  else
    return nil
  end
end
local function win_is_valid(win)
  return ((nil ~= win) and nvim.nvim_win_is_valid(win))
end
local function win_get_cursor(win)
  if win then
    return nvim.nvim_win_get_cursor(win)
  else
    return nil
  end
end
local function win_set_cursor(win, pos)
  if win then
    return nvim.nvim_win_set_cursor(win, pos)
  else
    return nil
  end
end
local function create_namespace(name)
  return nvim.nvim_create_namespace(name)
end
local function buf_set_extmark(buf, ns_id, line, col, opts)
  return nvim.nvim_buf_set_extmark(buf, ns_id, line, col, (opts or {}))
end
local function buf_del_extmark(buf, ns_id, id)
  return nvim.nvim_buf_del_extmark(buf, ns_id, id)
end
local function buf_get_extmarks(buf, ns_id, start, _end, opts)
  return nvim.nvim_buf_get_extmarks(buf, ns_id, start, _end, (opts or {}))
end
local function set_option(scope, id, key, value)
  if (scope == "win") then
    return nvim.nvim_set_option_value(key, value, {win = id})
  elseif (scope == "buf") then
    return nvim.nvim_set_option_value(key, value, {buf = id})
  elseif (scope == "global") then
    return nvim.nvim_set_option_value(key, value, {})
  else
    return nil
  end
end
local function get_option(scope, id, key)
  if (scope == "win") then
    return nvim.nvim_get_option_value(key, {win = id})
  elseif (scope == "buf") then
    return nvim.nvim_get_option_value(key, {buf = id})
  elseif (scope == "global") then
    return nvim.nvim_get_option_value(key, {})
  else
    return nil
  end
end
local function set_hl(ns, group, opts)
  return nvim.nvim_set_hl(ns, group, opts)
end
local function create_user_command(name, f, opts)
  return nvim.nvim_create_user_command(name, f, (opts or {}))
end
local function create_autocmd(event, opts)
  return nvim.nvim_create_autocmd(event, opts)
end
local function set_keymap(mode, lhs, rhs, opts)
  return vim.keymap.set(mode, lhs, rhs, (opts or {}))
end
local function schedule(f)
  return vim.schedule(f)
end
local function defer(f, ms)
  return vim.defer_fn(f, ms)
end
local function editor_width()
  return vim.o.columns
end
local function editor_height()
  return vim.o.lines
end
return {["buf-set-lines"] = buf_set_lines, ["buf-get-lines"] = buf_get_lines, ["buf-line-count"] = buf_line_count, ["buf-is-valid"] = buf_is_valid, ["buf-create"] = buf_create, ["buf-set-keymap"] = buf_set_keymap, ["win-open"] = win_open, ["win-close"] = win_close, ["win-is-valid"] = win_is_valid, ["win-get-cursor"] = win_get_cursor, ["win-set-cursor"] = win_set_cursor, ["create-namespace"] = create_namespace, ["buf-set-extmark"] = buf_set_extmark, ["buf-del-extmark"] = buf_del_extmark, ["buf-get-extmarks"] = buf_get_extmarks, ["set-option"] = set_option, ["get-option"] = get_option, ["set-hl"] = set_hl, ["create-user-command"] = create_user_command, ["create-autocmd"] = create_autocmd, ["set-keymap"] = set_keymap, schedule = schedule, defer = defer, ["editor-width"] = editor_width, ["editor-height"] = editor_height}
