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
local function status_first_path(parts, index, record, tab, separated_3f)
  if separated_3f then
    return string.sub(record, (tab + 1))
  else
    return parts[(index + 1)]
  end
end
local function status_old_path(rename, first_path)
  if rename then
    return first_path
  else
    return nil
  end
end
local function status_offset(separated_3f)
  if separated_3f then
    return 1
  else
    return 2
  end
end
local function status_destination(parts, index, rename, separated_3f, first_path)
  if rename then
    return parts[(index + status_offset(separated_3f))]
  else
    return first_path
  end
end
local function status_rename_offset(separated_3f)
  if separated_3f then
    return 2
  else
    return 3
  end
end
local function status_normal_offset(separated_3f)
  if separated_3f then
    return 1
  else
    return 2
  end
end
local function status_next_index(index, rename, separated_3f)
  if rename then
    return (index + status_rename_offset(separated_3f))
  else
    return (index + status_normal_offset(separated_3f))
  end
end
local function parse_status_parts_step(parts, index, result, recurse)
  local record = parts[index]
  local tab = string.find(record, "\t")
  local status = status_letter(string.sub(record, 1, (tab or 1)))
  local rename = ((status == "R") or (status == "C"))
  local separated_3f = (tab ~= nil)
  local first_path = status_first_path(parts, index, record, tab, separated_3f)
  local old_path = status_old_path(rename, first_path)
  local destination = status_destination(parts, index, rename, separated_3f, first_path)
  local next_index = status_next_index(index, rename, separated_3f)
  return recurse(parts, next_index, add_status(result, status, destination, old_path))
end
local function parse_status_parts(parts, index, result)
  if (index > #parts) then
    return result
  else
    return parse_status_parts_step(parts, index, result, parse_status_parts)
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
local function hunk_count(new_count)
  if (new_count == "") then
    return 1
  else
    return tonumber(new_count)
  end
end
local function hunk_line(line)
  local new_start, new_count = string.match(line, "^@@ %-[0-9]+,?[0-9]* %+(%d+),?(%d*)")
  local count = hunk_count(new_count)
  return (new_start and {start = tonumber(new_start), ["end"] = (tonumber(new_start) + math.max(count, 1) + -1)})
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
local function overlaps_step(form, intervals, index, recurse)
  local interval = intervals[index]
  if ((interval.start <= form["end-line"]) and (form.line <= interval["end"])) then
    return true
  else
    return recurse(form, intervals, (index + 1))
  end
end
local function overlaps_3f(form, intervals, index)
  if (index > #intervals) then
    return false
  else
    return overlaps_step(form, intervals, index, overlaps_3f)
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
local function add_record_path_new(state, seen_key, items_key, path)
  local result = append_if_new(state[seen_key], state[items_key], path)
  return core.assoc(core.assoc(state, seen_key, result.seen), items_key, result.items)
end
local function add_record_path(state, seen_key, items_key, path)
  if state[seen_key][path] then
    return state
  else
    return add_record_path_new(state, seen_key, items_key, path)
  end
end
local function add_whole_record(state, record)
  return (((record.status == "A") or (record.status == "R") or (record.status == "C")) and add_record_path(state, "whole-set", "whole", record.path))
end
local function add_deleted_record(state, record)
  return ((record.status == "D") and add_record_path(state, "deleted-set", "deleted", record.path))
end
local function add_hunk_record(state, record)
  return ((record.status == "M") and add_record_path(state, "hunks-set", "hunks", record.path))
end
local function add_record(state, record)
  return (add_whole_record(state, record) or add_deleted_record(state, record) or add_hunk_record(state, record) or state)
end
local function add_old_path_new(state, record)
  local result = append_if_new(state["deleted-set"], state.deleted, record["old-path"])
  return core.assoc(state, "deleted-set", result.seen, "deleted", result.items)
end
local function add_old_path(state, record)
  if (((record.status == "R") or (record.status == "C")) and record["old-path"] and not state["deleted-set"][record["old-path"]]) then
    return add_old_path_new(state, record)
  else
    return state
  end
end
local function add_untracked_path_new(state, path)
  local result = append_if_new(state["whole-set"], state.whole, path)
  return core.assoc(state, "whole-set", result.seen, "whole", result.items)
end
local function add_untracked_path(state, path)
  if ((path == nil) or state["whole-set"][path]) then
    return state
  else
    return add_untracked_path_new(state, path)
  end
end
local function add_records(initial, records)
  local state = initial
  for _, record in ipairs(records) do
    state = add_record(state, record)
  end
  return state
end
local function add_old_paths(initial, records)
  local state = initial
  for _, record in ipairs(records) do
    state = add_old_path(state, record)
  end
  return state
end
local function add_untracked_paths(initial, untracked)
  local state = initial
  for _, path in ipairs(untracked) do
    state = add_untracked_path(state, path)
  end
  return state
end
local function plan_state(records, untracked)
  return add_old_paths(add_records(add_untracked_paths({["whole-set"] = {}, ["hunks-set"] = {}, ["deleted-set"] = {}, whole = {}, hunks = {}, deleted = {}}, untracked), records), records)
end
local function plan_result(final_state)
  table.sort(final_state.whole)
  table.sort(final_state.hunks)
  table.sort(final_state.deleted)
  return {whole = final_state.whole, hunks = final_state.hunks, deleted = final_state.deleted}
end
local plan
do
  local function plan0(records, untracked)
    return plan_result(plan_state(records, untracked))
  end
  _2amodule_2a["plan"] = plan0
  plan = _2amodule_2a.plan
end
return nil
