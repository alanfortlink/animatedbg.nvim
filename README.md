## animatedbg.nvim

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
animatedbg.play({ animation = "fireworks" }) -- fireworks | demo
```

### Known Issues

- The "canvas" will be the width of your window but the size of your buf. Make sure you have enough lines to se the animations :)
  - So far I have figured out how to paint beyong the end of line, but I haven't figured out how to paint beyond the end of the buffer.

