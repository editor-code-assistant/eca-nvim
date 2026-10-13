-- [nfnl] fnl/spec/eca/ui/widgets/message-list_spec.fnl
local function with_cleanup(cleanup, f)
  local ok, result = pcall(f)
  cleanup()
  if ok then
    return result
  else
    return error(result, 0)
  end
end
local function with_api_stubs(stubs, f)
  local originals = {}
  for name, stub in pairs(stubs) do
    originals[name] = vim.api[name]
    vim.api[name] = stub
  end
  local function _2_()
    for name, original in pairs(originals) do
      vim.api[name] = original
    end
    return nil
  end
  return with_cleanup(_2_, f)
end
local function with_message_list(f)
  local original_message = package.loaded["eca.ui.components.message"]
  local original_widget = package.loaded["eca.ui.widgets.message-list"]
  local original_defer_fn = vim.defer_fn
  local function _3_(_)
    return {lines = {""}, highlights = {}}
  end
  package.loaded["eca.ui.components.message"] = {render = _3_}
  package.loaded["eca.ui.widgets.message-list"] = nil
  local function _4_()
    package.loaded["eca.ui.components.message"] = original_message
    package.loaded["eca.ui.widgets.message-list"] = original_widget
    vim.defer_fn = original_defer_fn
    return nil
  end
  local function _5_()
    local function _6_(_)
      return 1
    end
    local function _7_(_, _0, _1, _2)
      return nil
    end
    local function _8_(_, _0, _1, _2, _3)
      return nil
    end
    local function _9_(_, _0, _1, _2, _3)
      return nil
    end
    local function _10_(_)
      return 2
    end
    local function _11_(_, _0, _1, _2, _3, _4, _5)
      return nil
    end
    local function _12_()
      return f(require("eca.ui.widgets.message-list"))
    end
    return with_api_stubs({nvim_create_namespace = _6_, nvim_buf_clear_namespace = _7_, nvim_buf_set_extmark = _8_, nvim_buf_set_lines = _9_, nvim_buf_line_count = _10_, nvim_buf_set_text = _11_}, _12_)
  end
  return with_cleanup(_4_, _5_)
end
local function append_after_streaming_scenario()
  local defer_calls = {}
  local function _13_(message_list)
    local function _14_(callback, _)
      table.insert(defer_calls, callback)
      return "timer"
    end
    vim.defer_fn = _14_
    local widget = message_list.create(1)
    widget["append-message"]({id = "first", content = "abc", ["streaming?"] = true})
    local ok, result
    local function _15_()
      return widget["append-message"]({id = "second", content = "done", ["streaming?"] = true})
    end
    ok, result = pcall(_15_)
    return {ok = ok, result = result, ["streaming-id"] = widget["get-state"]()["streaming-id"], ["defer-calls"] = defer_calls}
  end
  return with_message_list(_13_)
end
local function _16_()
  local function _17_()
    local assert_5_auto = require("luassert")
    local expected_6_auto = true
    local actual_7_auto = append_after_streaming_scenario().ok
    assert_5_auto.same(expected_6_auto, actual_7_auto)
    return true
  end
  return require("plenary.busted").it("finishes an active stream before starting the next stream", _17_)
end
return require("plenary.busted").describe("append-message", _16_)
