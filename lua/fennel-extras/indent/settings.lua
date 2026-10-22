-- [nfnl] fnl/fennel-extras/indent/settings.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.indent.settings"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.indent.settings"]
end
local core = require("eca.nfnl.core")
local parse = require("fennel-extras.config.parse")
local binding_defaults = {"let", "when-let", "if-let", "with-open"}
local clause_defaults = {"case", "match", "case-try", "match-try", "if"}
local toggle_keys = {"bindings", "maps", "clauses", "split-bindings", "collapse-padding"}
local list_keys = {"binding-forms", "clause-forms"}
local function boolean_3f(value)
  return ((value == true) or (value == false))
end
local function string_list_entry_3f(value, index)
  local item = value[index]
  if (item == nil) then
    return true
  else
    return ((type(item) == "string") and string_list_entry_3f(value, (index + 1)))
  end
end
local function string_list_3f(value)
  if parse["sequence?"](value) then
    return string_list_entry_3f(value, 1)
  else
    return false
  end
end
local function list_contains_entry_3f(items, name, index)
  local item = items[index]
  if (item == nil) then
    return false
  else
    return ((item == name) or list_contains_entry_3f(items, name, (index + 1)))
  end
end
local function list_contains_3f(items, name)
  return list_contains_entry_3f(items, name, 1)
end
local function toggle_key_3f(key)
  return list_contains_3f(toggle_keys, key)
end
local function known_key_3f(key)
  return (toggle_key_3f(key) or list_contains_3f(list_keys, key))
end
local function key_error(message, key)
  return {message = ("alignment key " .. key .. message)}
end
local function validate_toggle(key, value)
  if not boolean_3f(value) then
    return key_error(" must be a boolean", key)
  else
    return nil
  end
end
local function validate_list(key, value)
  if not string_list_3f(value) then
    return key_error(" must be a list of strings", key)
  else
    return nil
  end
end
local function validate_known_entry(key, value)
  if toggle_key_3f(key) then
    return validate_toggle(key, value)
  else
    return validate_list(key, value)
  end
end
local function validate_entry(key, value)
  if not known_key_3f(key) then
    return {message = ("unknown alignment key: " .. key)}
  else
    return validate_known_entry(key, value)
  end
end
local function validate_entries(value, key)
  local next_key, item = next(value, key)
  local failure = (next_key and validate_entry(next_key, item))
  if (next_key == nil) then
    return nil
  else
    return (failure or validate_entries(value, next_key))
  end
end
local function validate_table(value)
  if (type(value) == "table") then
    return validate_entries(value, nil)
  else
    return nil
  end
end
local validate
do
  local function validate0(value)
    if ((value ~= nil) and (type(value) ~= "table")) then
      return {message = "alignment must be a table"}
    else
      return validate_table(value)
    end
  end
  _2amodule_2a["validate"] = validate0
  validate = _2amodule_2a.validate
end
local function toggle_value(alignment, legacy, key)
  if (alignment[key] ~= nil) then
    return alignment[key]
  else
    return legacy
  end
end
local resolve
do
  local function resolve0(config)
    local alignment = ((config and config.alignment) or {})
    local legacy = (config and config["align-bindings"])
    local enabled = (legacy == true)
    return {bindings = toggle_value(alignment, enabled, "bindings"), maps = toggle_value(alignment, enabled, "maps"), clauses = toggle_value(alignment, enabled, "clauses"), ["split-bindings"] = toggle_value(alignment, enabled, "split-bindings"), ["collapse-padding"] = toggle_value(alignment, enabled, "collapse-padding"), ["binding-forms"] = (alignment["binding-forms"] or binding_defaults), ["clause-forms"] = (alignment["clause-forms"] or clause_defaults)}
  end
  _2amodule_2a["resolve"] = resolve0
  resolve = _2amodule_2a.resolve
end
local function add_binding_forms(alignment, explicit)
  if (explicit and explicit["binding-forms"]) then
    return core.assoc(alignment, "binding-forms", explicit["binding-forms"])
  else
    return alignment
  end
end
local function add_clause_forms(alignment, explicit)
  if (explicit and explicit["clause-forms"]) then
    return core.assoc(alignment, "clause-forms", explicit["clause-forms"])
  else
    return alignment
  end
end
local normalize
do
  local function normalize0(config)
    local resolved = resolve(config)
    local alignment = {bindings = resolved.bindings, maps = resolved.maps, clauses = resolved.clauses, ["split-bindings"] = resolved["split-bindings"], ["collapse-padding"] = resolved["collapse-padding"]}
    local explicit = config.alignment
    local with_binding_forms = add_binding_forms(alignment, explicit)
    local normalized = add_clause_forms(with_binding_forms, explicit)
    return core.assoc(config, "alignment", normalized)
  end
  _2amodule_2a["normalize"] = normalize0
  normalize = _2amodule_2a.normalize
end
local binding_form_3f
do
  local function binding_form_3f0(alignment, name)
    return list_contains_3f(alignment["binding-forms"], name)
  end
  _2amodule_2a["binding-form?"] = binding_form_3f0
  binding_form_3f = _2amodule_2a["binding-form?"]
end
local clause_form_3f
do
  local function clause_form_3f0(alignment, name)
    return list_contains_3f(alignment["clause-forms"], name)
  end
  _2amodule_2a["clause-form?"] = clause_form_3f0
  clause_form_3f = _2amodule_2a["clause-form?"]
end
return nil
