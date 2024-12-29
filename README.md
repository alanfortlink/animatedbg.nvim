## animatedbg.nvim

Create/play animations inside neovim's buffer.

[matrix.webm](https://github.com/user-attachments/assets/f89fb100-57dd-4fe5-8497-cb92f97773f2)
[fireworks.webm](https://github.com/user-attachments/assets/96c0a839-b007-4acc-8910-704391bbcf7f)
[demo.webm](https://github.com/user-attachments/assets/a92a9210-4088-4786-8536-0cd98e7717fb)

## Installation

### With Lazy

```lua
{
  'alanfortlink/animatedbg.nvim',
  config = function ()
    require("animatedbg-nvim").setup({
        fps = 60 -- default
    })
  end
}
```

### Usage

```lua
local animatedbg = require("animatedbg-nvim")
animatedbg.play({ animation = "fireworks" }) -- fireworks | matrix | demo 
-- animatedbg.play({ animation = "matrix", duration = 20 }) -- some support duration
-- animatedbg.stop_all() -- if you don't want to wait
```

### Creating custom animations

It's very easy to add your own animation.

You need to prove an animation builder that contains:
- A unique `id`
- A `create(opts)` function that returns an animation.
  - `opts` contains information about the buffer, window, and size (`opts.rows` and `opts.cols`).
  - See some examples of how it is used in `./lua/animatedbg-nvim/animations`.

The animation table that is returned by `create` must have:
- `init()`, called once, right before the animation starts
- `update(dt) : boolean`, called before every frame is rendered. `dt` is the interval since the last frame in seconds.
  - It should return `true` if the animation is still playing and `false` when it's over.
- `render(canvas)`, called every frame for rendering.

One could write an animation/builder like this:

```lua
--- @type AnimationBuilder
local custom_animation_builder = {
  id = "unique_name",
  create = function(opts)
    local elapsed = 0.0

    --- @type Animation
    return {
      init = function()
      end,

      update = function(dt)
        elapsed = elapsed + dt
        return elapsed <= 3 -- ends after 3 seconds
      end,

      render = function(canvas)
        local center = { row = math.floor(opts.rows / 2), col = math.floor(opts.cols / 2) }

        --- @type Rect
        local rect = {
          row = center.row - 10,
          col = center.col - 10,
          rows = 20,
          cols = 20,
        }

        local decoration = { bg = "#FFFFFF", fg = "#FF0000", content = 'X' }
        canvas.draw_rect(rect, decoration)
      end,
    }
  end
}

```

and then set it up like this:

```lua
require("animatedbg-nvim").setup({
  builders = { custom_animation_builder }
})
```

### Share your animations.

If you build any animations and would like to share them, there's a [discussion page](https://github.com/alanfortlink/animatedbg.nvim/discussions/1) that you can use.

### Known Issues

- The "canvas" will be the width of your window but the size of your buf. Make sure you have enough lines in order to see the animations :)
  - So far I have figured out how to paint beyond the end of line, but I haven't figured out how to paint beyond the end of the buffer.

