local utils = require("animatedbg-nvim.utils")

--- @type AnimationBuilder
local M = {
  id = "fireworks",
  create = function(opts)
    local elapsed = 0.0
    local fireworks = {}
    local particles = {}
    local gravity = 10.0

    local move = function(obj, dt, gravity_override)
      obj.row_speed = obj.row_speed + (gravity_override or gravity) * dt
      obj.col = obj.col + obj.col_speed * dt
      obj.row = obj.row + obj.row_speed * dt
    end

    --- @type Animation
    local I = {
      init = function()
        gravity = 0.05 * opts.rows

        elapsed = 0.0
        for i = 0, 20, 1 do
          local col = math.random(0, opts.cols)
          local row = opts.rows + i * 0.2 * opts.rows

          local row_speed = -math.random(0.4 * opts.rows, 0.8 * opts.rows)
          local col_speed = math.random(-15, 15)

          local row_limit = math.random(0.2 * opts.rows, 0.4 * opts.rows)

          local color = "#111111"

          local firework = {
            col = col,
            row = row,
            row_speed = row_speed,
            col_speed = col_speed,
            color = color,
            row_limit = row_limit,
          }

          table.insert(fireworks, firework)
        end
      end,

      update = function(dt)
        elapsed = elapsed + dt

        local filtered_fireworks = {}
        for _, f in ipairs(fireworks) do
          move(f, dt, 0.3 * gravity)
          f.color = utils.brighten(f.color, 0.09)
          if f.row > f.row_limit and f.row_speed < 0 then
            table.insert(filtered_fireworks, f)
          else
            local num_particles = 16.0
            for i = 0, num_particles - 1, 1 do
              local angle = 2 * math.pi * (i / (num_particles))
              local row_speed, col_speed = utils.rotate(8, 0, angle)
              row_speed = row_speed + 0.1 * f.row_speed
              -- col_speed = col_speed * (M.opts.cols / M.opts.rows)

              local particle = {
                row = f.row,
                col = f.col,
                row_speed = row_speed,
                col_speed = col_speed,
                color = f.color,
              }

              table.insert(particles, particle)
            end
          end
        end

        for _, p in ipairs(particles) do
          move(p, dt, 0)
        end

        fireworks = filtered_fireworks

        return elapsed <= 10
      end,

      render = function(canvas)
        for _, f in ipairs(fireworks) do
          -- local rect = { row = f.row, col = f.col, rows = 1, cols = 1 }
          -- canvas.draw_rect(rect, decoration)
          local decoration = { bg = f.color }
          local circle = { center = { row = f.row, col = f.col }, radius = 1 }
          canvas.draw_circle(circle, decoration, { painting_style = "line" })
        end

        for _, p in ipairs(particles) do
          local rect = { row = p.row, col = p.col, rows = 1, cols = 1 }
          local decoration = { fg = p.color, content = "*" }
          canvas.draw_rect(rect, decoration)
        end
      end

    }
    return I;
  end
}



return M
