local utils = require("animatedbg-nvim.utils")

local M = {}

--- @class Canvas
--- @field rows integer
--- @field cols integer
--- @field angle number
--- @field draw_rect fun(rect : Rect, decoration: Decoration, opts?: PaintingOpts)
--- @field draw_circle fun(circle : Circle, decoration: Decoration, opts?: PaintingOpts)
--- @field draw_polygon fun(polygon : Polygon, decoration: Decoration, opts?: PaintingOpts)

--- @class Decoration
--- @field bg string | nil
--- @field fg string | nil
--- @field content string | nil

--- @return Canvas
M.create = function()
  local C = {}

  --- Maps the `decoration` id to the highlight name
  ---
  --- We create highlights only for the colors that are used in the animation
  --- Also, some characters are not allowed to be used in a highlight's name
  --- @type table {hl: string, content: string|nil}
  C.active_hls = {}


  --- Maps the color a color like "#FFFFFF" to an id like 0x123456789
  ---
  --- The highlight name is derived from the color/decoration properties.
  --- Given that some symbols are not allowed to be used in highlight names,
  --- this maps the actual color to an id that'll be used to create a highlight name
  --- @type {string: string}
  C.color_to_id = {}

  --- Maps the content string of a decoration to an id like 0x123456789
  ---
  --- The highlight name is derived from the color/decoration properties.
  --- Given that some symbols are not allowed to be used in highlight names,
  --- this maps the actual content to an id that'll be used to create a highlight name
  --- @type {string: string}
  C.content_to_id = {}

  --- 2d grid with the decorations that'll be used
  --- Gets updated every frame
  --- @type (Decoration[])[]
  C.raw_canvas = {}

  --- (Re-)Initializes the canvas
  --- @param opts {rows: integer, cols : integer}
  C.setup = function(opts)
    C.raw_canvas = {}

    for i = 0, opts.rows - 1, 1 do
      C.raw_canvas[i] = {}
      for j = 0, opts.cols - 1, 1 do
        C.raw_canvas[i][j] = { content = nil, bg = nil, fg = nil }
      end
    end

    C.rows = opts.rows
    C.cols = opts.cols
  end

  C.prerender = function()
  end

  --- Gets the highlight associated with the given cell
  ---
  --- Returns nil if the cell is not being used in the frame.
  --- Otherwise, returns the highlight name and the content of the cell
  --- @param row integer
  --- @param col integer
  --- @return nil | { hl: string, content: string }
  C.get_hl = function(row, col)
    local C_row = C.raw_canvas[row]

    if not C_row then
      return nil
    end

    local cell = C.raw_canvas[row][col]
    if not cell then
      return nil
    end

    if not cell.content and not cell.bg and not cell.fg then
      return nil
    end

    local content_id = nil
    local bg_id = nil
    local fg_id = nil

    if cell.content then
      if C.content_to_id[cell.content] then
        content_id = C.content_to_id[cell.content]
      else
        content_id = tostring({}):sub(8)
        C.content_to_id[cell.content] = content_id
      end
    end

    if cell.bg then
      if C.color_to_id[cell.bg] then
        bg_id = C.color_to_id[cell.bg]
      else
        bg_id = tostring({}):sub(8)
        C.color_to_id[cell.bg] = bg_id
      end
    end

    if cell.fg then
      if C.color_to_id[cell.fg] then
        fg_id = C.color_to_id[cell.fg]
      else
        fg_id = tostring({}):sub(8)
        C.color_to_id[cell.fg] = fg_id
      end
    end

    local key = string.format("c%sf%sb%s", content_id, bg_id, fg_id)

    if C.active_hls[key] then
      return C.active_hls[key]
    end

    local hl_name = string.format("AnimBG%s", key)
    vim.api.nvim_set_hl(0, hl_name, { bg = cell.bg, fg = cell.fg })

    C.active_hls[key] = { hl = hl_name, content = cell.content }
    return { hl = hl_name, content = cell.content }
  end

  --- Clears the canvas by setting all the properties as null
  C.clear = function()
    for i = 0, C.rows - 1, 1 do
      C.raw_canvas[i] = {}
      for j = 0, C.cols - 1, 1 do
        C.raw_canvas[i][j] = { content = nil, bg = nil, fg = nil }
      end
    end
  end

  --- @class Rect
  --- table with row, col, rows, cols
  --- (row, col) represent the top left of the rect
  --- rows stands for the number of rows that the rect will span
  --- cols stand for the number of columns that the rect will span
  --- @field row integer
  --- @field col integer
  --- @field rows integer
  --- @field cols integer

  --- @class Point
  --- @field row number
  --- @field col number

  --- @param rect Rect
  --- @param point Point
  --- @param threshold number
  --- @return "border"|"inside"|"outside"
  local function get_point_status_in_rect(rect, point, threshold)
    rect.row = math.floor(rect.row)
    rect.col = math.floor(rect.col)

    if point.row == rect.row or point.row == rect.row + rect.rows - 1 then
      return "border"
    end

    if point.col == rect.col or point.col == rect.col + rect.cols - 1 then
      return "border"
    end

    if point.row >= rect.row and point.row < rect.row + rect.rows then
      if point.col >= rect.col and point.col < rect.col + rect.cols then
        return "inside"
      end
    end

    return "outside"
  end

  --- @class Circle
  --- @field center Point
  --- @field radius number

  --- @param circle Circle
  --- @param point Point
  --- @param threshold number
  --- @return "outside"|"border"|"inside"
  local function get_point_status_in_circle(circle, point, threshold)
    circle.center.row = math.floor(circle.center.row)
    circle.center.col = math.floor(circle.center.col)

    point.row = math.floor(point.row)
    point.col = math.floor(point.col)

    local row_term = math.pow(circle.center.row - point.row, 2)
    local col_term = math.pow(circle.center.col - point.col, 2)
    local dist = math.sqrt(row_term + col_term)

    if dist > circle.radius then
      return "outside"
    end

    if math.abs(dist - circle.radius) <= threshold then
      return "border"
    end

    return "inside"
  end

  --- @class Polygon
  --- @field vertices Point[]

  --- @param polygon Polygon
  --- @param point Point
  --- @param threshold number
  --- @return "outside"|"inside"|"border"
  local function get_point_status_in_polygon(polygon, point, threshold)
    local vertices = polygon.vertices
    local x, y = math.floor(point.col), math.floor(point.row)
    local inside = false
    local n = #vertices
    local j = n

    for i = 1, n do
      local xi, yi = math.floor(vertices[i].col), math.floor(vertices[i].row)
      local xj, yj = math.floor(vertices[j].col), math.floor(vertices[j].row)

      -- Check for border using distance from line segment
      local dx, dy = xj - xi, yj - yi
      local t = ((x - xi) * dx + (y - yi) * dy) / (dx * dx + dy * dy)
      t = math.max(0, math.min(1, t))
      local closestX, closestY = xi + t * dx, yi + t * dy
      local dist = math.sqrt((x - closestX) ^ 2 + (y - closestY) ^ 2)

      if dist <= threshold then
        return "border"
      end

      -- Ray-casting for inside check
      if ((yi > y) ~= (yj > y)) and
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
        inside = not inside
      end

      j = i
    end

    return inside and "inside" or "outside"
  end

  local rotate_rect = function(rect, opts)
    local angle = opts.rotation_angle or 0
    local center = opts.rotation_center

    local top_left = utils.rotate_to_point(rect.row, rect.col, angle, center)
    local top_right = utils.rotate_to_point(rect.row, rect.col + rect.cols - 1, angle, center)
    local bottom_left = utils.rotate_to_point(rect.row + rect.rows - 1, rect.col, angle, center)
    local bottom_right = utils.rotate_to_point(rect.row + rect.rows - 1, rect.col + rect.cols - 1, angle, center)

    local min_row = math.min(top_left.row, top_right.row, bottom_left.row, bottom_right.row)
    local min_col = math.min(top_left.col, top_right.col, bottom_left.col, bottom_right.col)

    local max_row = math.max(top_left.row, top_right.row, bottom_left.row, bottom_right.row)
    local max_col = math.max(top_left.col, top_right.col, bottom_left.col, bottom_right.col)

    rect = {
      row = math.floor(min_row),
      col = math.floor(min_col),
      rows = math.floor(max_row - min_row + 1),
      cols = math.floor(max_col - min_col + 1),
    }

    return rect
  end

  --- @class PaintingOpts
  --- @field painting_style? "fill"|"line"
  --- @field rotation_angle? number
  --- @field rotation_center? Point
  --- @field debug? boolean

  ---Draws all the points in a rect that are valid according to the classifier
  --- @param rect Rect
  --- @param decoration Decoration
  --- @param opts PaintingOpts
  --- @param classifier any -- TODO: function signature here?
  C.generic_draw = function(rect, decoration, opts, classifier)
    opts = opts or {}
    local painting_style = opts.painting_style or "fill"

    -- I was trying to fix the empty cells when rotating, but haven't figure it out yet
    -- rect = rotate_rect(rect, opts)

    if opts.debug then
      local outer_rect = { row = rect.row - 1, col = rect.col - 1, rows = rect.rows + 2, cols = rect.cols + 2 }
      C.draw_rect(outer_rect, { bg = "#FFFFFF", fg = "#000000", content = "X" }, { painting_style = "line" })
    end

    local end_row = rect.row + rect.rows
    for i = rect.row, end_row - 1, 1 do
      i = math.floor(i)

      if not C.raw_canvas[i] then
        goto next_row
      end

      local end_col = rect.col + rect.cols
      for j = rect.col, end_col - 1, 1 do
        j = math.floor(j)

        local ri, rj = utils.rotate(i, j, opts.rotation_angle or 0, opts.rotation_center)
        ri = math.floor(ri)
        rj = math.floor(rj)

        local status = classifier({ row = i, col = j })

        if painting_style == "line" and status ~= "border" then
          goto next_column
        end

        if status == "outside" then
          goto next_column
        end

        if not C.raw_canvas[ri] then
          goto next_column
        end

        if not C.raw_canvas[ri][rj] then
          goto next_column
        end

        C.raw_canvas[ri][rj] = decoration

        ::next_column::
      end

      ::next_row::
    end
  end

  --- @param rect Rect
  --- @param decoration Decoration
  --- @param opts? PaintingOpts
  C.draw_rect = function(rect, decoration, opts)
    opts = opts or {}

    C.generic_draw(rect, decoration, opts, function(point)
      return get_point_status_in_rect(rect, point, 1)
    end)
  end

  --- @param circle Circle
  --- @param decoration Decoration
  --- @param opts PaintingOpts
  C.draw_circle = function(circle, decoration, opts)
    opts = opts or {}

    local radius = circle.radius

    local rect = {
      row = circle.center.row - radius,
      col = circle.center.col - radius,
      rows = 2 * radius,
      cols = 2 * radius,
    }

    C.generic_draw(rect, decoration, opts, function(point)
      return get_point_status_in_circle(circle, point, math.sqrt(2))
    end)
  end


  --- @param polygon Polygon
  --- @param decoration Decoration
  --- @param opts PaintingOpts
  C.draw_polygon = function(polygon, decoration, opts)
    -- for _, v in ipairs(polygon.vertices) do
    --   v.row, v.col = utils.rotate(v.row, v.col, opts.rotation_angle or 0, opts.rotation_center)
    -- end

    local top_row = C.rows
    local bottom_row = 0

    local left_col = C.cols
    local right_col = 0

    for _, p in ipairs(polygon.vertices) do
      top_row = math.min(top_row, p.row)
      left_col = math.min(left_col, p.col)

      bottom_row = math.max(bottom_row, p.row)
      right_col = math.max(right_col, p.col)
    end

    local rect = {
      row = top_row,
      col = left_col,
      rows = bottom_row - top_row + 1,
      cols = right_col - left_col + 1,
    }

    C.generic_draw(rect, decoration, opts, function(point)
      return get_point_status_in_polygon(polygon, point, 1)
    end)
  end

  return C
end

return M
