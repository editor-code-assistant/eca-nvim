-- [nfnl] fnl/eca/ui/components/usage.fnl
local function format_tokens(n)
  if (nil == n) then
    return "0"
  elseif (n >= 1000000) then
    return string.format("%.1fM", (n / 1000000))
  elseif (n >= 1000) then
    return string.format("%.0fK", (n / 1000))
  else
    return tostring(n)
  end
end
local function format_cost(cost)
  if (nil == cost) then
    return nil
  else
    return string.format("$%.2f", cost)
  end
end
local function render(_3_)
  local tokens_in = _3_["tokens-in"]
  local tokens_out = _3_["tokens-out"]
  local max_tokens = _3_["max-tokens"]
  local cost = _3_.cost
  local used = format_tokens(((tokens_in or 0) + (tokens_out or 0)))
  local max = format_tokens(max_tokens)
  local base
  if max_tokens then
    base = (used .. "/" .. max)
  else
    base = used
  end
  local cost_str = format_cost(cost)
  local text
  if cost_str then
    text = (base .. " (" .. cost_str .. ")")
  else
    text = base
  end
  return {text = text, ["hl-group"] = "EcaUsage"}
end
return {render = render, ["format-tokens"] = format_tokens, ["format-cost"] = format_cost}
