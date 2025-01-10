local utils = require("animatedbg-nvim.utils")

--- @type AnimationBuilder
local M = {
  id = "explosion",
  create = function(opts)
    opts = opts or {}
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
        gravity = 0.075 * opts.rows

        local r = math.random(150, 255)
        local g = math.random(150, 255)
        local b = math.random(150, 255)
        local color = utils.join_color(r, g, b)

        --- @type Point
        local origin = { row = opts.row or opts.rows / 2, col = opts.col or opts.cols / 2 }

        local num_particles = 16.0
        for i = 0, num_particles - 1, 1 do
          local angle = 2 * math.pi * (i / (num_particles))
          local row_speed, col_speed = utils.rotate(15, 0, angle)

          local particle = {
            row = origin.row,
            col = origin.col,
            row_speed = row_speed,
            col_speed = col_speed,
            color = color,
            ttl = math.random(1, 2),
            elapsed = 0,
          }

          table.insert(particles, particle)
        end
      end,

      update = function(dt)
        local filtered_particles = {}
        for _, p in ipairs(particles) do
          if p.ttl <= 0 then
            goto continue
          end

          if p.row > opts.rows then
            goto continue
          end

          if p.col > opts.cols or p.col < 0 then
            goto continue
          end

          move(p, dt, 3 * gravity)
          p.ttl = p.ttl - dt
          p.elapsed = p.elapsed + dt

          if p.elapsed >= 0.25 then
            p.row_speed = 0.5 * p.row_speed
            p.col_speed = 0.5 * p.col_speed
            p.elapsed = p.elapsed - 0.25
            p.color = utils.darken(p.color, 0.2)
          end

          if p.color == "#000000" then
            goto continue
          end

          table.insert(filtered_particles, p)

          ::continue::
        end

        particles = filtered_particles

        return #particles > 0
      end,

      render = function(canvas)
        for _, p in ipairs(particles) do
          local rect = { row = math.floor(p.row), col = math.floor(p.col), rows = math.floor(1), cols = math.floor(1), }
          local decoration = { fg = p.color, content = "*" }
          canvas.draw_rect(rect, decoration)
        end
      end

    }
    return I;
  end
}



return M
