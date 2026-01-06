---@class eca.StreamQueue
---@field private queue table Array of items to process
---@field private running boolean Whether the queue is currently processing
---@field private on_process function Callback to process each item
---@field private should_continue function Optional callback to check if processing should continue
---@field private chars_per_tick number Number of characters to display per tick
---@field private tick_delay number Delay between ticks in milliseconds

local M = {}
M.__index = M

---Create a new stream queue
---@param on_process function Function to call for each character batch: fn(text, is_complete)
---@param opts? table Optional configuration { chars_per_tick: number, tick_delay: number, should_continue: function }
---@return eca.StreamQueue
function M.new(on_process, opts)
  opts = opts or {}
  local instance = setmetatable({}, M)
  instance.queue = {}
  instance.running = false
  instance.on_process = on_process
  instance.should_continue = opts.should_continue
  instance.chars_per_tick = opts.chars_per_tick or 1
  instance.tick_delay = opts.tick_delay or 10
  return instance
end

---Add text to the queue for processing
---@param text string Text to add to the queue
function M:enqueue(text)
  if not text or text == "" then
    return
  end
  table.insert(self.queue, text)
  self:process()
end

---Process the queue
function M:process()
  -- If already processing or queue is empty, return early
  if self.running or #self.queue == 0 then
    return
  end

  self.running = true

  -- Combine all queued text into a single character queue for smooth continuous streaming
  local combined_text = table.concat(self.queue, "")
  self.queue = {}

  -- Create a local queue of characters from all text chunks
  local char_queue = {}
  for i = 1, #combined_text do
    table.insert(char_queue, combined_text:sub(i, i))
  end

  local function done()
    self.running = false
    -- Process next item in queue if available (in case new items were added during processing)
    if #self.queue > 0 then
      self:process()
    end
  end

  local function step()
    -- Check if we should continue processing (e.g., streaming is still active)
    if self.should_continue and not self.should_continue() then
      done()
      return
    end

    -- Check if new items were added to the queue while we were processing
    -- If so, add them to the current character queue to maintain smooth animation
    if #self.queue > 0 then
      local new_text = table.concat(self.queue, "")
      self.queue = {}
      for i = 1, #new_text do
        table.insert(char_queue, new_text:sub(i, i))
      end
    end

    -- If no more characters in this chunk, mark as done
    if #char_queue == 0 then
      done()
      return
    end

    -- Render a small batch of characters per tick
    local count = math.min(self.chars_per_tick, #char_queue)
    local chunk = ""
    for i = 1, count do
      chunk = chunk .. table.remove(char_queue, 1)
    end

    -- Call the process callback with the chunk
    -- Pass true if this is the last chunk
    local is_complete = #char_queue == 0 and #self.queue == 0
    self.on_process(chunk, is_complete)

    -- Continue processing this chunk
    vim.defer_fn(step, self.tick_delay)
  end

  -- Start processing this chunk
  vim.defer_fn(step, 1)
end

---Clear the queue and stop processing
function M:clear()
  self.queue = {}
  self.running = false
end

---Check if the queue is empty
---@return boolean
function M:is_empty()
  return #self.queue == 0 and not self.running
end

---Get the current queue size
---@return number
function M:size()
  return #self.queue
end

return M
