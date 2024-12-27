local utils = require("animatedbg-nvim.utils")

--- @type AnimationBuilder

--- @class Cell
--- @field pos Point
--- @field velocity number
--- @field symbol string
--- @field trail string[]
--- @field trail_limit integer

local matrix_symbols = {
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", -- Numbers
  "!", "@", "#", "$", "%", "&", "*", "(", ")", -- Symbols
  "⟦", "⟧", "⟨", "⟩", "⟪", "⟫", "⊢", "⊣", "⊕", "⊖", -- Math/Logic
  "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", -- Greek letters
  "∆", "Σ", "Ω", "Ψ", "Φ", -- Greek symbols
  "∑", "∫", "∴", "∞", "∇", "∂", -- Calculus/Math symbols
  "⊂", "⊃", "⊆", "⊇", "∅", "∧", "∨", -- Set theory and logic
  "↔", "→", "←", "↑", "↓", -- Arrows
  "◆", "◇", "■", "□", "▲", "△", "▼", "▽", -- Geometric shapes
  "⌂", "☰", "☲", "☵", "☷" -- Miscellaneous symbols
}

local get_random_symbol = function()
  return matrix_symbols[math.random(1, #matrix_symbols)]
end

local M = {
  id = "matrix",
  create = function(opts)
    --- @type Cell[]
    local cells = {};
    local elapsed = 0.0
    local last_addition = 0.0

    local cols_to_re_add = (function()
      local all_cols = {}
      for i = 1, opts.cols do
        table.insert(all_cols, i)
      end
      return all_cols
    end)()

    local create_new_cells = function()
      for _, col in ipairs(cols_to_re_add) do
        local row = math.random(-2 * opts.rows, -1)

        --- @type Cell
        local cell = {
          pos = { row = row, col = col },
          velocity = math.floor(math.random(8, 12)),
          symbol = get_random_symbol(),
          trail = {},
          trail_limit = opts.rows / 2,
        }

        table.insert(cells, cell)
      end

      cols_to_re_add = {}
    end

    local move_cells = function(dt)
      --- @type Cell[]
      local new_cells = {}

      for _, cell in ipairs(cells) do
        --- @type Cell
        local new_cell = {
          pos = { row = cell.pos.row + cell.velocity * dt, col = cell.pos.col },
          velocity = cell.velocity,
          symbol = cell.symbol,
          trail = cell.trail,
          trail_limit = cell.trail_limit,
        }

        if math.floor(new_cell.pos.row) ~= math.floor(cell.pos.row) then
          if #cell.trail < cell.trail_limit then
            table.insert(cell.trail, 1, get_random_symbol())
          else
            table.remove(cell.trail, #cell.trail)
            table.insert(cell.trail, 1, get_random_symbol())
          end
        end

        if new_cell.pos.row >= 2 * opts.rows then
          table.insert(cols_to_re_add, new_cell.pos.col)
        else
          table.insert(new_cells, new_cell)
        end
      end

      cells = new_cells
    end

    --- @type Animation
    return {
      init = function()
      end,

      update = function(dt)
        elapsed = elapsed + dt

        if elapsed - last_addition >= 0.5 then
          create_new_cells()
        end

        move_cells(dt)

        return elapsed <= 10 -- ends after 10 seconds
      end,

      render = function(canvas)
        for _, cell in ipairs(cells) do
          if cell.pos.row < 0 or cell.pos.row >= 2 * opts.rows then
            goto continue
          end

          if cell.pos.col < 0 or cell.pos.col >= opts.cols then
            goto continue
          end

          local rect = {
            row = math.floor(cell.pos.row),
            col = cell.pos.col,
            rows = 1,
            cols = 1,
          }

          local bg = "#000000"
          local fg = "#00FF00"
          local content = cell.symbol

          local fac = 0.1

          local decoration = { bg = bg, fg = fg, content = content }
          canvas.draw_rect(rect, decoration)

          for _, t in ipairs(cell.trail) do
            rect.row = rect.row - 1

            bg = utils.darken(bg, fac)
            fg = utils.darken(fg, fac)

            content = t

            decoration = { bg = bg, fg = fg, content = content }
            canvas.draw_rect(rect, decoration)
          end

          ::continue::
        end
      end,
    }
  end
}

return M
