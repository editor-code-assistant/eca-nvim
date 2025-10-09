---@diagnostic disable: undefined-global
local api = vim.api

local Utils = require("eca.utils")
local Logger = require("eca.logger")
local Sidebar = require("eca.sidebar")
local Config = require("eca.config")
local Server = require("eca.server")

---@class Eca
local M = {
  ---@type eca.Sidebar[] we use this to track chat command across tabs
  sidebars = {},
  ---@type {sidebar?: eca.Sidebar}
  current = { sidebar = nil },
  ---@type eca.Server
  server = nil,
}

M.did_setup = false

local H = {}

function H.keymaps()
  vim.keymap.set({ "n", "v" }, "<Plug>(EcaChat)", function()
    require("eca.api").chat()
  end, { noremap = true })
  vim.keymap.set("n", "<Plug>(EcaToggle)", function()
    M.toggle()
  end, { noremap = true })
  vim.keymap.set("n", "<Plug>(EcaFocus)", function()
    require("eca.api").focus()
  end, { noremap = true })

  if Config.behaviour.auto_set_keymaps then
    Utils.safe_keymap_set({ "n", "v" }, Config.mappings.chat, function()
      require("eca.api").chat()
    end, { desc = "eca: open chat" })
    Utils.safe_keymap_set("n", Config.mappings.focus, function()
      require("eca.api").focus()
    end, { desc = "eca: focus" })
    Utils.safe_keymap_set("n", Config.mappings.toggle, function()
      M.toggle()
    end, { desc = "eca: toggle" })
  end
end

function H.signs()
  vim.fn.sign_define("EcaInputPromptSign", { text = Config.windows.input.prefix })
end

H.augroup = api.nvim_create_augroup("eca_autocmds", { clear = true })

function H.autocmds()
  api.nvim_create_autocmd("TabEnter", {
    group = H.augroup,
    pattern = "*",
    once = true,
    callback = function(ev)
      local tab = tonumber(ev.file)
      M._init(tab or api.nvim_get_current_tabpage())
    end,
  })

  api.nvim_create_autocmd("VimResized", {
    group = H.augroup,
    callback = function()
      local sidebar = M.get()
      if not sidebar then
        return
      end
      if not sidebar:is_open() then
        return
      end
      sidebar:resize()
    end,
  })

  api.nvim_create_autocmd("QuitPre", {
    group = H.augroup,
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()
      if Utils.is_sidebar_buffer(current_buf) then
        return
      end

      local non_sidebar_wins = 0
      local sidebar_wins = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local win_buf = vim.api.nvim_win_get_buf(win)
          if Utils.is_sidebar_buffer(win_buf) then
            table.insert(sidebar_wins, win)
          else
            non_sidebar_wins = non_sidebar_wins + 1
          end
        end
      end

      if non_sidebar_wins <= 1 then
        for _, win in ipairs(sidebar_wins) do
          pcall(vim.api.nvim_win_close, win, false)
        end
      end
    end,
    nested = true,
  })

  api.nvim_create_autocmd("TabClosed", {
    group = H.augroup,
    pattern = "*",
    callback = function(ev)
      local tab = tonumber(ev.file)
      local s = M.sidebars[tab]
      if s then
        s:reset()
      end
      if tab ~= nil then
        M.sidebars[tab] = nil
      end
    end,
  })

  vim.schedule(function()
    M._init(api.nvim_get_current_tabpage())
  end)

  local function setup_colors()
    Logger.debug("Setting up eca colors")
    require("eca.highlights").setup()
  end

  api.nvim_create_autocmd("ColorSchemePre", {
    group = H.augroup,
    callback = function()
      vim.schedule(function()
        setup_colors()
      end)
    end,
  })

  api.nvim_create_autocmd("ColorScheme", {
    group = H.augroup,
    callback = function()
      vim.schedule(function()
        setup_colors()
      end)
    end,
  })

  -- automatically setup Eca filetype to markdown
  vim.treesitter.language.register("markdown", "Eca")
end

---@param current boolean? false to disable setting current, otherwise use this to track across tabs.
---@return eca.Sidebar
function M.get(current)
  local tab = api.nvim_get_current_tabpage()
  local sidebar = M.sidebars[tab]
  if current ~= false then
    M.current.sidebar = sidebar
  end
  return sidebar
end

---@param id integer
function M._init(id)
  local sidebar = M.sidebars[id]

  if not sidebar then
    sidebar = Sidebar.new(id, M.mediator)
    M.sidebars[id] = sidebar
  end
  M.current = { sidebar = sidebar }
  return M
end

M.toggle = { api = true }

---@param opts? table
function M.toggle_sidebar(opts)
  opts = opts or {}

  local sidebar = M.get()
  if not sidebar then
    M._init(api.nvim_get_current_tabpage())
    M.current.sidebar:open(opts)
    return true
  end

  return sidebar:toggle(opts)
end

function M.is_sidebar_open()
  local sidebar = M.get()
  if not sidebar then
    return false
  end
  return sidebar:is_open()
end

---@param opts? table
function M.open_sidebar(opts)
  opts = opts or {}
  local sidebar = M.get()
  if not sidebar then
    M._init(api.nvim_get_current_tabpage())
  end
  M.current.sidebar:open(opts)
end

function M.close_sidebar()
  local sidebar = M.get()
  if not sidebar then
    return
  end
  sidebar:close()
end

setmetatable(M.toggle, {
  __index = M.toggle,
  __call = function()
    M.toggle_sidebar()
  end,
})

---@param opts? eca.Config
function M.setup(opts)
  Config.setup(opts or {})

  if M.did_setup then
    return
  end

  require("eca.logger").setup(Config.options.log)
  require("eca.highlights").setup()
  require("eca.commands").setup()

  -- setup helpers
  H.autocmds()
  H.keymaps()
  H.signs()

  -- Initialize the ECA server with callbacks
  M.state = require("eca.state").new()
  M.server = Server.new()
  M.mediator = require("eca.mediator").new(M.server, M.state)
  -- Start server automatically in background
  vim.defer_fn(function()
    M.server:start()
  end, 100) -- Small delay to ensure everything is loaded

  M.did_setup = true
end

return M
