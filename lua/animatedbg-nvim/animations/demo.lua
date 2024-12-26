--- @type AnimationBuilder
local M = {
  id = "demo",

  create = function(_)
    --- @type number
    local elapsed = 0.0 -- Counting how long we've been animating

    local make_even = function(num)
      if num % 2 ~= 0 then
        return num + 1
      end

      return num
    end

    return {
      init = function()
        elapsed = 0.0
      end,

      update = function(dt)
        elapsed = elapsed + dt
        return elapsed <= 5 -- Animation is over after 5 seconds
      end,

      --- @param canvas Canvas
      render = function(canvas)
        local even_rows = make_even(canvas.rows) + 1
        local even_cols = make_even(canvas.cols)

        local rows = 10
        local cols = 30

        local center = { row = even_rows / 2, col = even_cols / 2 }

        local top = center.row - rows / 2
        local left = center.col - cols / 2

        local bottom = center.row + rows / 2 - 1
        local right = center.col + cols / 2 - 1

        local rot_duration = 2
        local angle = 2 * math.pi * (elapsed % rot_duration) / rot_duration
        if elapsed <= 2 or elapsed >= 4 then
          angle = 0
        end

        local opts = { rotation_angle = angle, rotation_center = center }

        --- @type Rect
        local green_rect = { row = top, col = left, rows = rows, cols = cols }
        --- @type Decoration
        local green_dec = { bg = "#009739" }

        canvas.draw_rect(green_rect, green_dec, opts)

        --- @type Polygon
        local yellow_polygon = {
          vertices = {
            { row = top,        col = center.col },
            { row = center.row, col = right },
            { row = bottom,     col = center.col },
            { row = center.row, col = left },
          }
        }
        local yellow_dec = { bg = "#FEDD00" }
        canvas.draw_polygon(yellow_polygon, yellow_dec, opts)

        --- @type Circle
        local blue_circle = { center = { row = center.row, col = center.col }, radius = rows / 2 }
        local blue_dec = { bg = "#012169" }

        canvas.draw_circle(blue_circle, blue_dec)

        --- @type Rect
        local white_rect = { row = center.row - 1, col = center.col - rows / 2 + 1, rows = 3, cols = rows - 1 }
        local white_dec = { bg = "#FFFFFF" }
        canvas.draw_rect(white_rect, white_dec, opts)

        local text_cell1 = { row = center.row, col = center.col - 1, rows = 1, cols = 1 }
        local text_dec1 = { bg = "#FFFFFF", fg = "#009739", content = "H" }
        canvas.draw_rect(text_cell1, text_dec1, opts)

        local text_cell2 = { row = center.row, col = center.col, rows = 1, cols = 1 }
        local text_dec2 = { bg = "#FFFFFF", fg = "#009739", content = "U" }
        canvas.draw_rect(text_cell2, text_dec2, opts)

        local text_cell3 = { row = center.row, col = center.col + 1, rows = 1, cols = 1 }
        local text_dec3 = { bg = "#FFFFFF", fg = "#009739", content = "E" }
        canvas.draw_rect(text_cell3, text_dec3, opts)
      end
    }
  end
}

return M


































--
