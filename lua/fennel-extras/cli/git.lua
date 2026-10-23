-- [nfnl] fnl/fennel-extras/cli/git.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.git"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.git"]
end
local lint_selection = require("fennel-extras.lint.selection")
local table_copy = require("fennel-extras.cli.table")
local function trim_newlines(text)
  return string.gsub(text, "\n+$", "")
end
local function git_arguments(args)
  local tbl_26_ = {}
  local i_27_ = 0
  for _, arg in ipairs(args) do
    local val_28_ = vim.fn.shellescape(arg)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function git_command(root, args)
  local escaped = git_arguments(args)
  return ("git -C " .. vim.fn.shellescape(root) .. " " .. table.concat(escaped, " "))
end
local function git_output(output, marker)
  local case_2_ = not marker
  if (case_2_ == true) then
    return output, 2
  elseif (case_2_ == false) then
    return string.sub(output, 1, (marker - 1)), tonumber(string.sub(output, (marker + 15)))
  else
    return nil
  end
end
local function git_read_output(file)
  if file then
    return file:read("*a")
  else
    return ""
  end
end
local function git_call(root, args)
  local file = io.popen((git_command(root, args) .. " </dev/null 2>&1; printf '\\n__ECA_STATUS__%s' $?"))
  local output = git_read_output(file)
  if file then
    file:close()
  else
  end
  return git_output(output, string.find(output, "\n__ECA_STATUS__"))
end
local function git_root(start)
  local output, status = git_call(start, {"rev-parse", "--show-toplevel"})
  if (status == 0) then
    return trim_newlines(output)
  else
    return nil
  end
end
local function git_plan_change_success(ctx, status_text, untracked_text)
  local records = lint_selection["parse-name-status"](status_text)
  local untracked = lint_selection["parse-untracked"](untracked_text)
  return {root = ctx.root, records = records, untracked = untracked, plan = lint_selection.plan(records, untracked)}, nil
end
local function git_plan_change_data(ctx, status)
  if ((status["status-code"] ~= 0) or (status["untracked-code"] ~= 0)) then
    return nil, {message = "could not inspect Git changes"}
  else
    return git_plan_change_success(ctx, status["status-text"], status["untracked-text"])
  end
end
local function git_plan_changed_data(ctx)
  local status_text, status_code = git_call(ctx.root, {"diff", "--name-status", "-z", "--find-renames", "--find-copies", ctx.base, "--"})
  local untracked_text, untracked_code = git_call(ctx.root, {"ls-files", "--others", "--exclude-standard", "-z"})
  return git_plan_change_data(ctx, {["status-text"] = status_text, ["status-code"] = status_code, ["untracked-text"] = untracked_text, ["untracked-code"] = untracked_code})
end
local function git_plan_changed(ctx)
  local _, resolved_status = git_call(ctx.root, {"rev-parse", "--verify", (ctx.base .. "^{commit}")})
  if (resolved_status == 0) then
    return git_plan_changed_data(ctx)
  else
    return nil, {message = ("unknown base ref: " .. ctx.base)}
  end
end
local function git_plan_root_mode(ctx)
  if ctx.parsed.all then
    return {root = ctx.root}, nil
  else
    return git_plan_changed(ctx)
  end
end
local function git_plan_root(ctx, shallow, shallow_status)
  if ((shallow_status == 0) and (trim_newlines(shallow) == "true")) then
    return nil, {message = "lint requires a full clone; shallow repositories are not supported"}
  else
    return git_plan_root_mode(ctx)
  end
end
local function git_plan_root_check(ctx)
  local shallow, shallow_status = git_call(ctx.root, {"rev-parse", "--is-shallow-repository"})
  return git_plan_root(ctx, shallow, shallow_status)
end
local function git_plan(start, parsed)
  local root = git_root(start)
  local ctx = {root = root, parsed = parsed, base = (parsed.base or "HEAD")}
  if (root == nil) then
    return nil, {message = "lint requires a Git repository"}
  else
    return git_plan_root_check(ctx)
  end
end
local function path_present_3f(paths, path, index)
  if (index > #paths) then
    return false
  elseif (path == paths[index]) then
    return true
  else
    return path_present_3f(paths, path, (index + 1))
  end
end
local function changed_file_result(file, patch, status)
  if (status == 0) then
    return {path = file.path, source = file.source, selection = lint_selection["parse-hunks"](patch)}
  else
    return nil
  end
end
local function changed_file_hunks(root, base, file)
  local patch, status = git_call(root, {"diff", "--unified=0", "--no-color", "--no-ext-diff", base, "--", file.path})
  return changed_file_result(file, patch, status)
end
local function changed_file(root, base, file, whole_3f)
  if whole_3f then
    return {path = file.path, source = file.source, selection = true}
  else
    return changed_file_hunks(root, base, file)
  end
end
local function append_selected(result, selected)
  table.insert(result, selected)
  return result
end
local function changed_result(result, selected)
  if selected then
    return append_selected(result, selected)
  else
    return result
  end
end
local function changed_file_selection(ctx, file)
  local whole_3f = path_present_3f(ctx.plan.whole, file.path, 1)
  local hunk_3f = path_present_3f(ctx.plan.hunks, file.path, 1)
  return ((whole_3f or hunk_3f) and changed_file(ctx.root, ctx.base, file, whole_3f))
end
local function changed_files_next(ctx, state)
  local file = ctx.files[state.index]
  local selected = changed_file_selection(ctx, file)
  local result = changed_result(state.result, selected)
  return {index = (state.index + 1), result = result}
end
local function changed_files_step(ctx, state)
  if (state.index > #ctx.files) then
    return state.result
  else
    return changed_files_step(ctx, changed_files_next(ctx, state))
  end
end
local emit_git_error
do
  local function emit_git_error0(printer, error)
    printer((error.message or error))
    return 2
  end
  _2amodule_2a["emit-git-error"] = emit_git_error0
  emit_git_error = _2amodule_2a["emit-git-error"]
end
local function scope_paths(plan)
  local result = {}
  for _, path in ipairs(plan.whole) do
    table.insert(result, path)
  end
  for _, path in ipairs(plan.hunks) do
    table.insert(result, path)
  end
  for _, path in ipairs(plan.deleted) do
    table.insert(result, path)
  end
  return result
end
local lint_git_info
do
  local function lint_git_info0(root, parsed, require_git_3f)
    if require_git_3f then
      return git_plan(root, parsed)
    else
      return {root = root, plan = {whole = {}, hunks = {}, deleted = {}}}, nil
    end
  end
  _2amodule_2a["lint-git-info"] = lint_git_info0
  lint_git_info = _2amodule_2a["lint-git-info"]
end
local lint_selection0
do
  local function lint_selection1(parsed, sources, git_info)
    if parsed.changed then
      return changed_files_step({root = git_info.root, base = (parsed.base or "HEAD"), files = sources, plan = git_info.plan}, {index = 1, result = {}}), scope_paths(git_info.plan)
    else
      return sources, nil
    end
  end
  _2amodule_2a["lint-selection"] = lint_selection1
  lint_selection0 = _2amodule_2a["lint-selection"]
end
return nil
