-- [nfnl] fnl/fennel-extras/cli/fs.fnl
local _2amodule_2a
do
  local pkg_1_auto = require("package")
  pkg_1_auto.loaded["fennel-extras.cli.fs"] = {}
  _2amodule_2a = pkg_1_auto.loaded["fennel-extras.cli.fs"]
end
local table_copy = require("fennel-extras.cli.table")
local function read_open_file(file)
  local text = file:read("*a")
  file:close()
  return text, nil
end
local read_file
do
  local function read_file0(path)
    local file = io.open(path, "r")
    if file then
      return read_open_file(file)
    else
      return nil, {message = ("could not read file: " .. path)}
    end
  end
  _2amodule_2a["read-file"] = read_file0
  read_file = _2amodule_2a["read-file"]
end
local function temp_write_error(temp, write_error, close_error)
  os.remove(temp)
  return nil, (write_error or close_error or "could not write temporary file")
end
local function temp_open_error(state)
  if string.match(tostring(state.error), "EEXIST") then
    return state["loop-fn"](table_copy.update(state, {attempt = (state.attempt + 1)}))
  else
    return nil, nil, state.error
  end
end
local function temp_open_result(state)
  if (state.ok and state.fd) then
    return state.temp, state.fd, nil
  else
    return temp_open_error(state)
  end
end
local function temp_open_attempt(state)
  local temp = (state.path .. ".tmp-" .. tostring(math.random(1000000000)))
  local ok, fd, error = pcall(state.uv.fs_open, temp, "wx", 420)
  return temp_open_result(table_copy.update(state, {temp = temp, ok = ok, fd = fd, error = error}))
end
local function temp_open_loop(state)
  if (state.attempt > state["max-attempts"]) then
    return nil, nil, "could not open temporary file"
  else
    return temp_open_attempt(state)
  end
end
local function temp_write_open(uv, temp, file, text)
  local write_ok, written, write_error = pcall(uv.fs_write, file, text)
  local close_ok, close_result, close_error = pcall(uv.fs_close, file)
  if (not write_ok or not written or write_error or not close_ok or not close_result or close_error) then
    return temp_write_error(temp, write_error, close_error)
  else
    return temp, nil
  end
end
local temp_write
do
  local function temp_write0(path, text)
    local uv = (vim.uv or vim.loop)
    local temp, file, open_error = temp_open_loop({["loop-fn"] = temp_open_loop, uv = uv, path = path, attempt = 1, ["max-attempts"] = 10})
    if open_error then
      return nil, open_error
    else
      return temp_write_open(uv, temp, file, text)
    end
  end
  _2amodule_2a["temp-write"] = temp_write0
  temp_write = _2amodule_2a["temp-write"]
end
return nil
