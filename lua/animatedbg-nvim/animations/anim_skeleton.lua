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
        return elapsed <= 5 -- Animation is over after 5 seconds
      end,

      --- @param canvas Canvas
      render = function(canvas)
        local rows = 15
        local cols = 30

        local duration = 5.0
        local angle = 2 * math.pi * ((elapsed % duration) / duration)

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
          rotation_angle = angle,
          rotation_center = center,
        }
        canvas.draw_rect(rect, decoration, opts)
      end
    }
  end
}

return M


































--
