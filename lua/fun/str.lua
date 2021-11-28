
local ssub = string.sub
local sbyte = string.byte
local sfind = string.find
local band = bit.band

local function empty()
end


local function iter_chars(state, idx)
  if (idx ~= #state) then
    local idx0 = (idx + 1)
    local char = ssub(state, idx0, idx0)
    return idx0, char
  else
    return nil
  end
end


local function iter_chars_rev(state, idx)
  if (1 ~= idx) then
    local idx0 = (idx - 1)
    local char = ssub(state, idx0, idx0)
    return idx0, char
  else
    return nil
  end
end


local function iter_bytes(state, idx)
  if (idx ~= #state) then
    local idx0 = (idx + 1)
    local val = sbyte(state, idx0)
    return idx0, val
  else
    return nil
  end
end


local function iter_bytes_rev(state, idx)
  if (1 ~= idx) then
    local idx0 = (idx - 1)
    local val = sbyte(state, idx0)
    return idx0, val
  else
    return nil
  end
end

--- @param text string
--- @return fun(state: string, idx: integer): integer, string
--- @return string
--- @return integer
local function string_chars(text)
  return iter_chars, text, 0
end


--- @param text string
--- @return fun(state: string, idx: integer): integer, string
--- @return string
--- @return integer
local function string_chars_reversed(text)
  if (0 ~= #text) then
    return iter_chars_rev, text, (#text + 1)
  else
    return empty, nil, nil
  end
end


--- @param text string
--- @return fun(state: string, idx: integer): integer, integer
--- @return string
--- @return integer
local function string_bytes(text)
  return iter_bytes, text, 0
end


--- @param text string
--- @return fun(state: string, idx: integer): integer, integer
--- @return string
--- @return integer
local function string_bytes_reversed(text)
  if (0 ~= #text) then
    return iter_bytes_rev, text, (#text + 1)
  else
    return empty, "", 0
  end
end


local function iter_split_plain(state, idx)
  local len = #state[1]
  if (idx ~= len) then
    local idx0 = (idx + 1)
    local start, stop = sfind(state[1], state[2], idx0, true)
    if (nil ~= start) then
      return stop, ssub(state[1], idx0, (start - 1))
    else
      return len, ssub(state[1], idx0, len)
    end
  else
    return nil
  end
end


local function iter_split_pattern(state, idx)
  local len = #state[1]
  if (idx ~= len) then
    local idx0 = (idx + 1)
    local start, stop = sfind(state[1], state[2], idx0, false)
    if (nil ~= start) then
      return stop, ssub(state[1], idx0, (start - 1))
    else
      return len, ssub(state[1], idx0, len)
    end
  else
    return nil
  end
end

--- @param separator string
--- @param text string
--- @return fun(state: table, idx: integer): integer, string
--- @return table
--- @return integer
local function string_split(separator, text)
  if (("" == text) or ("" == separator)) then
    return empty, nil, 0
  else
    return iter_split_plain, {text, separator}, 0
  end
end


--- @param separator string
--- @param text string
--- @return fun(state: table, idx: integer): integer, string
--- @return table
--- @return integer
local function string_split_pattern(separator, text)
  if (("" == text) or ("" == separator)) then
    return empty, nil, nil
  else
    return iter_split_pattern, {text, separator}, 0
  end
end


local function utf8_forward_step(val)
  if (band(val, 128) == 0) then
    return 0
  elseif (band(val, 224) == 192) then
    return 1
  elseif (band(val, 240) == 224) then
    return 2
  elseif (band(val, 248) == 240) then
    return 3
  elseif (band(val, 252) == 248) then
    return 4
  elseif (band(val, 254) == 252) then
    return 5
  else
    return 0
  end
end


local function utf8_forward(str, at)
  return at, (at + utf8_forward_step(sbyte(str, at)))
end


local function utf8_backward(str, at)
  if (band(sbyte(str, at), 128) == 0) then
    return at, at
  else
    local nidx = (at - 1)
    while ((nidx ~= 1) and (band(sbyte(str, nidx), 192) == 128)) do
      nidx = (nidx - 1)
    end
    return nidx, at
  end
end


local function iter_utf8_pos(state, idx)
  if (idx < #state) then
    local fr, to = utf8_forward(state, (idx + 1))
    return to, fr, to
  else
    return nil
  end
end


local function iter_utf8_pos_reversed(state, idx)
  if (1 < idx) then
    local fr, to = utf8_backward(state, (idx - 1))
    return fr, fr, to
  else
    return nil
  end
end


local function iter_utf8(state, idx)
  if (idx < #state) then
    local fr, to = utf8_forward(state, (idx + 1))
    return to, ssub(state, fr, to)
  else
    return nil
  end
end


local function iter_utf8_reversed(state, idx)
  if (1 < idx) then
    local fr, to = utf8_backward(state, (idx - 1))
    return fr, ssub(state, fr, to)
  else
    return nil
  end
end


--- @param text string
--- @return fun(state: string, idx: integer): integer, integer, integer
--- @return string
--- @return integer
local function utf8_pos(text)
  if (0 < #text) then
    return iter_utf8_pos, text, 0
  else
    return empty, "", 0
  end
end


--- @param text string
--- @return fun(state: string, idx: integer): integer, integer, integer
--- @return string
--- @return integer
local function rutf8_pos(text)
  if (0 < #text) then
    return iter_utf8_pos_reversed, text, (#text + 1)
  else
    return empty, "", 0
  end
end


--- @param text string
--- @return fun(state: string, idx: integer): integer, string
--- @return string
--- @return integer
local function utf8(text)
  if (0 < #text) then
    return iter_utf8, text, 0
  else
    return empty, "", 0
  end
end


--- @param text string
--- @return fun(state: string, idx: integer): integer, string
--- @return string
--- @return integer
local function rutf8(text)
  if (0 < #text) then
    return iter_utf8_reversed, text, (#text + 1)
  else
    return empty, "", 0
  end
end


return {
    chars = string_chars,
    bytes = string_bytes,
    rchars = string_chars_reversed,
    rbytes = string_bytes_reversed,
    split = string_split,
    splitpat = string_split_pattern,
    utf8 = utf8,
    rutf8 = rutf8,
    utf8_pos = utf8_pos,
    rutf8_pos = rutf8_pos,
}
