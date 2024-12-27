## animatedbg.nvim

Create/play animations inside neovim's buffer.





https://github.com/user-attachments/assets/2f4231f7-37cd-4765-81cc-eca03295b458




https://github.com/user-attachments/assets/2caacd51-ac48-4dfd-bcfe-67f744b26fa0




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

- The "canvas" will be the width of your window but the size of your buf. Make sure you have enough lines in order to see the animations :)
  - So far I have figured out how to paint beyond the end of line, but I haven't figured out how to paint beyond the end of the buffer.

