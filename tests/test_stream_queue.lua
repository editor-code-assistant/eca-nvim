local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[
        _G.StreamQueue = require('eca.stream_queue')
        _G.output = ""
        _G.chunks_received = {}
      ]])
    end,
    post_once = child.stop,
  },
})

-- Ensure scheduled callbacks run (vim.schedule and vim.defer_fn)
local function flush(ms)
  vim.uv.sleep(ms or 50)
  -- Force at least one main loop iteration
  child.api.nvim_eval("1")
end

T["basic queue operations"] = MiniTest.new_set()

T["basic queue operations"]["creates a new queue instance"] = function()
  child.lua([[
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      -- noop
    end)
  ]])

  eq(child.lua_get("type(_G.queue)"), "table")
  eq(child.lua_get("_G.queue:is_empty()"), true)
  eq(child.lua_get("_G.queue:size()"), 0)
end

T["basic queue operations"]["enqueue triggers processing"] = function()
  child.lua([[
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      -- noop
    end)
    _G.queue:enqueue("Hello")
    _G.queue:enqueue("World")
  ]])

  -- When items are enqueued, the first starts processing immediately
  -- So size will be 1 (second item waiting) and not empty (still processing)
  local size = child.lua_get("_G.queue:size()")
  local is_empty = child.lua_get("_G.queue:is_empty()")

  -- Either 1 item in queue (first being processed) or 2 items (depending on timing)
  eq(size >= 0 and size <= 2, true)
  eq(is_empty, false)
end

T["basic queue operations"]["clear removes all items"] = function()
  child.lua([[
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      -- noop
    end)
    _G.queue:enqueue("Hello")
    _G.queue:enqueue("World")
    _G.queue:clear()
  ]])

  eq(child.lua_get("_G.queue:size()"), 0)
  eq(child.lua_get("_G.queue:is_empty()"), true)
end

T["queue processing"] = MiniTest.new_set()

T["queue processing"]["processes single text chunk"] = function()
  child.lua([[
    _G.output = ""
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
    end, {
      chars_per_tick = 2,
      tick_delay = 10,
    })
    _G.queue:enqueue("Hi")
  ]])

  -- Wait for processing to complete
  flush(100)

  eq(child.lua_get("_G.output"), "Hi")
  eq(child.lua_get("_G.queue:is_empty()"), true)
end

T["queue processing"]["processes multiple text chunks in order"] = function()
  child.lua([[
    _G.output = ""
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
    end, {
      chars_per_tick = 2,
      tick_delay = 5,
    })
    _G.queue:enqueue("Hello")
    _G.queue:enqueue(" ")
    _G.queue:enqueue("World")
    _G.queue:enqueue("!")
  ]])

  -- Wait for all processing to complete
  flush(300)

  eq(child.lua_get("_G.output"), "Hello World!")
  eq(child.lua_get("_G.queue:is_empty()"), true)
end

T["queue processing"]["respects chars_per_tick setting"] = function()
  child.lua([[
    _G.chunks_received = {}
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      table.insert(_G.chunks_received, chunk)
    end, {
      chars_per_tick = 1,
      tick_delay = 5,
    })
    _G.queue:enqueue("ABC")
  ]])

  -- Wait for processing to complete
  flush(100)

  -- With chars_per_tick = 1, "ABC" should be split into 3 chunks
  local chunks = child.lua_get("_G.chunks_received")
  eq(#chunks, 3)
  eq(chunks[1], "A")
  eq(chunks[2], "B")
  eq(chunks[3], "C")
end

T["queue processing"]["calls callback with is_complete flag"] = function()
  child.lua([[
    _G.completion_flags = {}
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      table.insert(_G.completion_flags, is_complete)
    end, {
      chars_per_tick = 2,
      tick_delay = 5,
    })
    _G.queue:enqueue("AB")
    _G.queue:enqueue("CD")
  ]])

  -- Wait for all processing to complete
  flush(150)

  local flags = child.lua_get("_G.completion_flags")
  -- The last chunk should have is_complete = true
  eq(flags[#flags], true)
end

T["queue processing"]["respects should_continue callback"] = function()
  child.lua([[
    _G.output = ""
    _G.should_continue = true
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
    end, {
      chars_per_tick = 1,
      tick_delay = 10,
      should_continue = function()
        return _G.should_continue
      end,
    })
    _G.queue:enqueue("ABCDEF")
  ]])

  -- Let it process a bit
  flush(30)

  -- Stop processing
  child.lua([[_G.should_continue = false]])

  -- Wait to ensure it stops
  flush(50)

  local output = child.lua_get("_G.output")
  -- Should have processed some but not all characters
  eq(#output < 6, true)
  eq(#output > 0, true)
end

T["edge cases"] = MiniTest.new_set()

T["edge cases"]["handles empty text gracefully"] = function()
  child.lua([[
    _G.callback_called = false
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.callback_called = true
    end)
    _G.queue:enqueue("")
  ]])

  flush(50)

  -- Empty text should not trigger processing
  eq(child.lua_get("_G.callback_called"), false)
end

T["edge cases"]["handles nil text gracefully"] = function()
  child.lua([[
    _G.callback_called = false
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.callback_called = true
    end)
    _G.queue:enqueue(nil)
  ]])

  flush(50)

  -- Nil text should not trigger processing
  eq(child.lua_get("_G.callback_called"), false)
end

T["edge cases"]["processes queue even with rapid enqueues"] = function()
  child.lua([[
    _G.output = ""
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
    end, {
      chars_per_tick = 2,
      tick_delay = 5,
    })
    -- Rapidly enqueue multiple items
    for i = 1, 10 do
      _G.queue:enqueue(tostring(i))
    end
  ]])

  -- Wait for all processing to complete
  flush(500)

  eq(child.lua_get("_G.output"), "12345678910")
  eq(child.lua_get("_G.queue:is_empty()"), true)
end

T["typing speed configuration"] = MiniTest.new_set()

T["typing speed configuration"]["default speed processes at expected rate"] = function()
  child.lua([[
    _G.start_time = vim.loop.hrtime()
    _G.output = ""
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
      if is_complete then
        _G.end_time = vim.loop.hrtime()
      end
    end, {
      chars_per_tick = 1,  -- Default: 1 char at a time
      tick_delay = 10,     -- Default: 10ms delay
    })
    _G.queue:enqueue("ABCDE")  -- 5 characters
  ]])

  -- With 1 char per tick and 10ms delay, 5 chars should take at least 40ms
  flush(100)

  eq(child.lua_get("_G.output"), "ABCDE")
  local duration_ns = child.lua_get("_G.end_time - _G.start_time")
  local duration_ms = duration_ns / 1000000
  -- Should take at least 40ms (5 chars * 10ms - overhead for first char)
  eq(duration_ms >= 30, true)
end

T["typing speed configuration"]["fast speed processes quickly"] = function()
  child.lua([[
    _G.output = ""
    _G.chunks_count = 0
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
      _G.chunks_count = _G.chunks_count + 1
    end, {
      chars_per_tick = 3,  -- Fast: 3 chars at a time
      tick_delay = 2,      -- Fast: 2ms delay
    })
    _G.queue:enqueue("ABCDEFGHI")  -- 9 characters
  ]])

  flush(50)

  eq(child.lua_get("_G.output"), "ABCDEFGHI")
  -- With 3 chars per tick, 9 chars should take 3 chunks
  eq(child.lua_get("_G.chunks_count"), 3)
end

T["typing speed configuration"]["slow speed processes slowly"] = function()
  child.lua([[
    _G.start_time = vim.loop.hrtime()
    _G.output = ""
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
      if is_complete then
        _G.end_time = vim.loop.hrtime()
      end
    end, {
      chars_per_tick = 1,  -- Slow: 1 char at a time
      tick_delay = 30,     -- Slow: 30ms delay
    })
    _G.queue:enqueue("ABC")  -- 3 characters
  ]])

  flush(150)

  eq(child.lua_get("_G.output"), "ABC")
  local duration_ns = child.lua_get("_G.end_time - _G.start_time")
  local duration_ms = duration_ns / 1000000
  -- Should take at least 60ms (3 chars * 30ms - overhead for first char)
  eq(duration_ms >= 50, true)
end

T["typing speed configuration"]["instant display with large chars_per_tick"] = function()
  child.lua([[
    _G.output = ""
    _G.chunks_count = 0
    _G.queue = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output = _G.output .. chunk
      _G.chunks_count = _G.chunks_count + 1
    end, {
      chars_per_tick = 1000,  -- Instant: large batch
      tick_delay = 0,          -- Instant: no delay
    })
    _G.queue:enqueue("Hello World!")  -- 12 characters
  ]])

  flush(50)

  eq(child.lua_get("_G.output"), "Hello World!")
  -- Should process in 1 chunk since chars_per_tick is larger than text
  eq(child.lua_get("_G.chunks_count"), 1)
end

T["typing speed configuration"]["different speeds for different queues"] = function()
  child.lua([[
    _G.output_fast = ""
    _G.output_slow = ""

    _G.queue_fast = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output_fast = _G.output_fast .. chunk
    end, {
      chars_per_tick = 5,
      tick_delay = 1,
    })

    _G.queue_slow = _G.StreamQueue.new(function(chunk, is_complete)
      _G.output_slow = _G.output_slow .. chunk
    end, {
      chars_per_tick = 1,
      tick_delay = 20,
    })

    _G.queue_fast:enqueue("FAST")
    _G.queue_slow:enqueue("SLOW")
  ]])

  -- Fast should complete quickly
  flush(50)
  eq(child.lua_get("_G.output_fast"), "FAST")

  -- Slow may still be processing
  flush(150)
  eq(child.lua_get("_G.output_slow"), "SLOW")
end

-- Integration tests with Sidebar
T["sidebar integration"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[
        -- Setup complete environment with Server, State, Mediator, Sidebar
        _G.Server = require('eca.server').new()
        _G.State = require('eca.state').new()
        _G.Mediator = require('eca.mediator').new(_G.Server, _G.State)
        _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)
        _G.Sidebar:open()
      ]])
    end,
    post_case = function()
      child.lua([[ if _G.Sidebar then _G.Sidebar:close() end ]])
    end,
  },
})

T["sidebar integration"]["initializes stream queue with default config"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar
    _G.queue_info = {
      exists = Sidebar._stream_queue ~= nil,
      is_empty = Sidebar._stream_queue and Sidebar._stream_queue:is_empty() or false,
    }
  ]])

  local info = child.lua_get("_G.queue_info")
  eq(info.exists, true)
  eq(info.is_empty, true)
end

T["sidebar integration"]["streams text with typing effect when enabled"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          typing = {
            enabled = true,
            chars_per_tick = 2,
            tick_delay = 5,
          },
        },
      },
    })

    -- Recreate sidebar with new config
    _G.Sidebar:close()
    _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)
    _G.Sidebar:open()

    local Sidebar = _G.Sidebar

    -- Simulate streaming text
    Sidebar:handle_chat_content_received({
      chatId = 'chat-typing',
      content = {
        type = 'text',
        text = 'Hello',
      },
    })

    -- Add another chunk (simulates multiple streaming updates)
    Sidebar:handle_chat_content_received({
      chatId = 'chat-typing',
      content = {
        type = 'text',
        text = ' World',
      },
    })
  ]])

  -- Wait for typing to complete with faster settings
  flush(200)

  child.lua([[
    local Sidebar = _G.Sidebar
    local total = Sidebar._current_response_buffer or ""
    _G.typing_info = {
      total = total,
      total_len = #total,
      queue_empty = Sidebar._stream_queue:is_empty(),
    }
  ]])

  local info = child.lua_get("_G.typing_info")
  eq(info.total_len, 11) -- "Hello World"
  eq(info.queue_empty, true)
end

T["sidebar integration"]["displays instantly when typing disabled"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          typing = {
            enabled = false,
          },
        },
      },
    })

    -- Recreate sidebar with new config
    _G.Sidebar:close()
    _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)
    _G.Sidebar:open()

    local Sidebar = _G.Sidebar

    -- Simulate streaming text
    Sidebar:handle_chat_content_received({
      chatId = 'chat-instant',
      content = {
        type = 'text',
        text = 'Instant Display',
      },
    })
  ]])

  -- With typing disabled, text should appear immediately
  flush(50)

  child.lua([[
    local Sidebar = _G.Sidebar
    _G.instant_info = {
      visible = Sidebar._stream_visible_buffer or "",
      total = Sidebar._current_response_buffer or "",
    }
  ]])

  local info = child.lua_get("_G.instant_info")
  eq(info.visible, "Instant Display")
  eq(info.total, "Instant Display")
end

T["sidebar integration"]["respects custom typing speed"] = function()
  child.lua([[
    local Config = require('eca.config')
    Config.override({
      windows = {
        chat = {
          typing = {
            enabled = true,
            chars_per_tick = 3,
            tick_delay = 5,
          },
        },
      },
    })

    -- Recreate sidebar with new config
    _G.Sidebar:close()
    _G.Sidebar = require('eca.sidebar').new(1, _G.Mediator)
    _G.Sidebar:open()

    local Sidebar = _G.Sidebar

    -- Simulate streaming text
    Sidebar:handle_chat_content_received({
      chatId = 'chat-fast',
      content = {
        type = 'text',
        text = 'ABCDEFGHI',
      },
    })
  ]])

  -- With chars_per_tick=3, should type faster
  flush(80)

  local final = child.lua_get("_G.Sidebar._stream_visible_buffer")
  eq(final, "ABCDEFGHI")
end

T["sidebar integration"]["clears queue on new chat"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar

    -- Start streaming
    Sidebar:handle_chat_content_received({
      chatId = 'chat-1',
      content = {
        type = 'text',
        text = 'First message',
      },
    })
  ]])

  flush(30)

  child.lua([[
    local Sidebar = _G.Sidebar
    _G.queue_size_before = Sidebar._stream_queue:size()

    -- Reset for new chat
    Sidebar:new_chat()

    _G.queue_size_after = Sidebar._stream_queue:size()
  ]])

  local size_after = child.lua_get("_G.queue_size_after")

  eq(size_after, 0)
  eq(child.lua_get("_G.Sidebar._stream_queue:is_empty()"), true)
end

T["sidebar integration"]["handles multiple text chunks in sequence"] = function()
  child.lua([[
    local Sidebar = _G.Sidebar

    -- Simulate multiple streaming chunks
    Sidebar:handle_chat_content_received({
      chatId = 'chat-multi',
      content = {
        type = 'text',
        text = 'First ',
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-multi',
      content = {
        type = 'text',
        text = 'Second ',
      },
    })

    Sidebar:handle_chat_content_received({
      chatId = 'chat-multi',
      content = {
        type = 'text',
        text = 'Third',
      },
    })
  ]])

  -- Wait for all chunks to be processed
  flush(300)

  local final = child.lua_get("_G.Sidebar._current_response_buffer")
  eq(final, "First Second Third")
end

return T
