local M = {}

local get_rows = function(window)
  return math.min(vim.api.nvim_buf_line_count(0), vim.api.nvim_win_get_height(window))
end

local get_cols = function(window)
  local total_width = vim.api.nvim_win_get_width(window)
  local number_width = vim.wo[window].number and vim.wo[window].numberwidth or 0
  local sign_column_width = vim.wo[window].signcolumn == "yes" and 2
      or (vim.wo[window].signcolumn == "auto" and 2 or 0)
  local fold_column_width = vim.wo[window].foldcolumn and tonumber(vim.wo[window].foldcolumn) or 0

  return total_width - number_width - sign_column_width - fold_column_width
end

M.get_win_size = function(window)
  return get_rows(window), get_cols(window)
end

M.get_scroll = function(window)
  local topline = vim.fn.line("w0", window)
  --- TODO: calculate the horizontal scroll too
  return topline, 0
end

--- @param row number
--- @param col number
--- @param angle number
--- @param center? Point
--- @return number, number
M.rotate = function(row, col, angle, center)
  center = center or { row = 0, col = 0 }
  -- Convert angle from degrees to radians
  local radians = angle

  local translated_row = row - center.row
  local translated_col = col - center.col

  local rotated_row = translated_row * math.cos(radians) - translated_col * math.sin(radians)
  local rotated_col = translated_row * math.sin(radians) + translated_col * math.cos(radians)

  local final_row = rotated_row + center.row
  local final_col = rotated_col + center.col

  return final_row, final_col
end

local split_color = function(rgb_color)
  assert(#rgb_color == 7, string.format("Expect rgb like '#FFFFFF', not %s", rgb_color))
  local r = tonumber(string.sub(rgb_color, 2, 3), 16);
  local g = tonumber(string.sub(rgb_color, 4, 5), 16);
  local b = tonumber(string.sub(rgb_color, 6, 7), 16);

  return r, g, b
end

local join_color = function(r, g, b)
  return string.format("#%02x%02x%02x", r, g, b)
end

local clamp_color = function(v)
  return math.min(255, math.max(v, 0))
end

M.brighten = function(rgb_color, factor)
  local r, g, b = split_color(rgb_color)
  r = clamp_color(r + r * factor)
  g = clamp_color(g + g * factor)
  b = clamp_color(b + b * factor)
  return join_color(r, g, b)
end

M.darken = function(rgb_color, factor)
  local r, g, b = split_color(rgb_color)
  r = clamp_color(r - r * factor)
  g = clamp_color(g - g * factor)
  b = clamp_color(b - b * factor)
  return join_color(r, g, b)
end

return M
