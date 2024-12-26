--- @type AnimationBuilder
local M = {
  id = "anim_skeleton",

  create = function(_)
    local elapsed = 0.0 -- Counting how long we've been animating

    return {
      init = function()
        elapsed = 0.0
      end,

      update = function(dt)
        elapsed = elapsed + dt
        return elapsed <= 3 -- Animation is over after 3 seconds
      end,

      --- @param canvas Canvas
      render = function(canvas)
        local rows = 10
        local cols = 20

        local center = { row = canvas.rows / 2, col = canvas.cols / 2 }

        --- @type Rect
        local rect = {
          row = center.row - rows / 2,
          col = center.col - cols / 2,
          rows = rows,
          cols = cols
        }

        --- @type Decoration
        local decoration = {
          bg = "#FFFFFF",
          fg = "#000000",
          content = "!",
        }

        --- @type PaintingOpts
        local opts = {
          painting_style = "line",
          rotation_angle = 0,
        }
        canvas.draw_rect(rect, decoration, opts)
      end
    }
  end
}

return M


































--
