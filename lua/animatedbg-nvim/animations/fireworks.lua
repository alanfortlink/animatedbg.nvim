local utils = require("animatedbg-nvim.utils")

--- @type AnimationBuilder
local M = {
  id = "fireworks",
  create = function(opts)
    opts = opts or {}
    local elapsed = 0.0
    local fireworks = {}
    local particles = {}
    local gravity = 10.0
    local time_of_last_shot = 0.0

    local time_between_shots = opts.time_between_shots or 0.5
    local duration = opts.duration or 10

    local move = function(obj, dt, gravity_override)
      obj.row_speed = obj.row_speed + (gravity_override or gravity) * dt
      obj.col = obj.col + obj.col_speed * dt
      obj.row = obj.row + obj.row_speed * dt
    end

    local fire = function()
      local col = math.random(0, opts.cols)
      local row = opts.rows + 0.2 * opts.rows

      local row_speed = -math.random(0.5 * opts.rows, 0.9 * opts.rows)
      local col_speed = math.random(-15, 15)

      local row_limit = math.random(0.2 * opts.rows, 0.5 * opts.rows)

      local r = math.random(150, 255)
      local g = math.random(150, 255)
      local b = math.random(150, 255)
      local color = utils.join_color(r, g, b)

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

    --- @type Animation
    local I = {
      init = function()
        gravity = 0.075 * opts.rows
        elapsed = 0.0
        fire()
      end,

      update = function(dt)
        elapsed = elapsed + dt

        if elapsed - time_of_last_shot >= time_between_shots then
          time_of_last_shot = elapsed
          fire()
        end

        local filtered_fireworks = {}
        for _, f in ipairs(fireworks) do
          move(f, dt, 0.3 * gravity)
          -- f.color = utils.brighten(f.color, 0.09)
          if f.row > f.row_limit and f.row_speed < 0 then
            table.insert(filtered_fireworks, f)
          else
            local num_particles = 16.0
            for i = 0, num_particles - 1, 1 do
              local angle = 2 * math.pi * (i / (num_particles))
              local row_speed, col_speed = utils.rotate(15, 0, angle)
              col_speed = col_speed * 2
              row_speed = row_speed + 0.1 * f.row_speed
              -- col_speed = col_speed * (M.opts.cols / M.opts.rows)

              local particle = {
                row = f.row,
                col = f.col,
                row_speed = row_speed,
                col_speed = col_speed,
                color = f.color,
                ttl = math.random(1, 2),
                elapsed = 0,
              }

              table.insert(particles, particle)
            end
          end
        end

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
            p.row_speed = 0.75 * p.row_speed
            p.col_speed = 0.75 * p.col_speed
            p.elapsed = p.elapsed - 0.25
            p.color = utils.darken(p.color, 0.2)
          end

          if p.color == "#000000" then
            goto continue
          end

          table.insert(filtered_particles, p)

          ::continue::
        end

        fireworks = filtered_fireworks
        particles = filtered_particles

        return elapsed <= duration
      end,

      render = function(canvas)
        for _, f in ipairs(fireworks) do
          local decoration = { bg = f.color }
          local rect = { row = math.floor(f.row), col = math.floor(f.col), rows = math.floor(1), cols = math.floor(1), }
          canvas.draw_rect(rect, decoration, { painting_style = "fill" })
        end

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
