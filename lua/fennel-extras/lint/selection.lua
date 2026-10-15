-- [nfnl] fnl/fennel-extras/lint/selection.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.lint.selection"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.lint.selection"]
end
local core = require("eca.nfnl.core")
local function append_item(result, value)
  return core.concat(result, {value})
end
local function add_status(result, status, path, old_path)
  return append_item(result, {status = status, path = path, ["old-path"] = old_path})
end
local function split_nul(text)
  local tbl_26_ = {}
  local i_27_ = 0
  for part in string.gmatch(text, "[^%z]+") do
    local val_28_ = part
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function status_letter(status)
  return string.sub(status, 1, 1)
end
local function parse_status_parts(parts, index, result)
  if (index > #parts) then
    return result
  else
    local record = parts[index]
    local tab = string.find(record, "\t")
    local status = status_letter(string.sub(record, 1, (tab or 1)))
    local rename = ((status == "R") or (status == "C"))
    local separated_3f = (tab ~= nil)
    local first_path
    if separated_3f then
      first_path = string.sub(record, (tab + 1))
    else
      first_path = parts[(index + 1)]
    end
    local old_path
    if rename then
      old_path = first_path
    else
      old_path = nil
    end
    local destination
    if rename then
      local _4_
      if separated_3f then
        _4_ = 1
      else
        _4_ = 2
      end
      destination = parts[(index + _4_)]
    else
      destination = first_path
    end
    local next_index
    if rename then
      local _7_
      if separated_3f then
        _7_ = 2
      else
        _7_ = 3
      end
      next_index = (index + _7_)
    else
      local _9_
      if separated_3f then
        _9_ = 1
      else
        _9_ = 2
      end
      next_index = (index + _9_)
    end
    return parse_status_parts(parts, next_index, add_status(result, status, destination, old_path))
  end
end
local parse_name_status
do
  local function parse_name_status0(text)
    local parts = split_nul(text)
    if (#parts == 0) then
      return {}
    else
      return parse_status_parts(parts, 1, {})
    end
  end
  _2amodule_2a["parse-name-status"] = parse_name_status0
  parse_name_status = _2amodule_2a["parse-name-status"]
end
local parse_untracked
do
  local function parse_untracked0(text)
    return split_nul(text)
  end
  _2amodule_2a["parse-untracked"] = parse_untracked0
  parse_untracked = _2amodule_2a["parse-untracked"]
end
local function split_lines(text)
  local tbl_26_ = {}
  local i_27_ = 0
  for line in string.gmatch(text, "[^\n]+") do
    local val_28_ = line
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function hunk_line(line)
  local new_start, new_count = string.match(line, "^@@ %-[0-9]+,?[0-9]* %+(%d+),?(%d*)")
  local count
  if (new_count == "") then
    count = 1
  else
    count = tonumber(new_count)
  end
  if new_start then
    return {start = tonumber(new_start), ["end"] = (tonumber(new_start) + math.max(count, 1) + -1)}
  else
    return nil
  end
end
local parse_hunks
do
  local function parse_hunks0(text)
    local tbl_26_ = {}
    local i_27_ = 0
    for _, line in ipairs(split_lines(text)) do
      local val_28_ = hunk_line(line)
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  end
  _2amodule_2a["parse-hunks"] = parse_hunks0
  parse_hunks = _2amodule_2a["parse-hunks"]
end
local function overlaps_3f(form, intervals, index)
  if (index > #intervals) then
    return false
  else
    local interval = intervals[index]
    if ((interval.start <= form["end-line"]) and (form.line <= interval["end"])) then
      return true
    else
      return overlaps_3f(form, intervals, (index + 1))
    end
  end
end
local form_selected_3f
do
  local function form_selected_3f0(form, intervals)
    return overlaps_3f(form, intervals, 1)
  end
  _2amodule_2a["form-selected?"] = form_selected_3f0
  form_selected_3f = _2amodule_2a["form-selected?"]
end
local function add_unique(items, value)
  if ((value == nil) or items[value]) then
    return items
  else
    return core.assoc(items, value, true)
  end
end
local function append_if_new(seen, items, value)
  if seen[value] then
    return {seen = seen, items = items}
  else
    return {seen = core.assoc(seen, value, true), items = append_item(items, value)}
  end
end
local function add_record(state, record)
  if ((record.status == "A") or (record.status == "R") or (record.status == "C")) then
    if not state["whole-set"][record.path] then
      local result = append_if_new(state["whole-set"], state.whole, record.path)
      return core.assoc(state, "whole-set", result.seen, "whole", result.items)
    else
      return state
    end
  else
    if (record.status == "D") then
      if not state["deleted-set"][record.path] then
        local result = append_if_new(state["deleted-set"], state.deleted, record.path)
        return core.assoc(state, "deleted-set", result.seen, "deleted", result.items)
      else
        return state
      end
    else
      if (record.status == "M") then
        if not state["hunks-set"][record.path] then
          local result = append_if_new(state["hunks-set"], state.hunks, record.path)
          return core.assoc(state, "hunks-set", result.seen, "hunks", result.items)
        else
          return state
        end
      else
        return state
      end
    end
  end
end
local function add_old_path(state, record)
  if (((record.status == "R") or (record.status == "C")) and record["old-path"] and not state["deleted-set"][record["old-path"]]) then
    local result = append_if_new(state["deleted-set"], state.deleted, record["old-path"])
    return core.assoc(state, "deleted-set", result.seen, "deleted", result.items)
  else
    return state
  end
end
local plan
do
  local function plan0(records, untracked)
    local initial = {["whole-set"] = {}, ["hunks-set"] = {}, ["deleted-set"] = {}, whole = {}, hunks = {}, deleted = {}}
    local with_untracked
    do
      local state = initial
      for _, path in ipairs(untracked) do
        if ((path == nil) or state["whole-set"][path]) then
          state = state
        else
          local result = append_if_new(state["whole-set"], state.whole, path)
          state = core.assoc(state, "whole-set", result.seen, "whole", result.items)
        end
      end
      with_untracked = state
    end
    local with_records
    do
      local state = with_untracked
      for _, record in ipairs(records) do
        state = add_record(state, record)
      end
      with_records = state
    end
    local final_state
    do
      local state = with_records
      for _, record in ipairs(records) do
        state = add_old_path(state, record)
      end
      final_state = state
    end
    table.sort(final_state.whole)
    table.sort(final_state.hunks)
    table.sort(final_state.deleted)
    return {whole = final_state.whole, hunks = final_state.hunks, deleted = final_state.deleted}
  end
  _2amodule_2a["plan"] = plan0
  plan = _2amodule_2a.plan
end
return nil
