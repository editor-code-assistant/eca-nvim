-- [nfnl] fnl/eca/ui/components/spinner.fnl
local frames = {"\226\160\139", "\226\160\153", "\226\160\185", "\226\160\184", "\226\160\188", "\226\160\180", "\226\160\166", "\226\160\167", "\226\160\135", "\226\160\143"}
local function render(_1_)
  local frame = _1_.frame
  local idx = (((frame or 0) % #frames) + 1)
  local char = frames[idx]
  return {text = char, ["hl-group"] = "EcaSpinner"}
end
local function frame_count()
  return #frames
end
return {render = render, ["frame-count"] = frame_count}
