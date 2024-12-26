--- @class Executor
--- @field start_new_animation fun(opts: ExecutorOpts)


--- @class ExecutorOpts
--- @field buffer integer
--- @field window integer
--- @field fps integer
--- @field builder AnimationBuilder
--- @field animation Animation
--- @field rows integer
--- @field cols integer
--- @field id string

local internal = {}
internal.last_id = 0
internal.animations = {}

local buf_to_canvas = {}
local renderer = require("animatedbg-nvim.renderer")

local is_execution_running = false
local global_dt = 0

--- @type Executor
local M = {

  --- @param opts ExecutorOpts
  start_new_animation = function(opts)
    if not buf_to_canvas[opts.buffer] then
      buf_to_canvas[opts.buffer] = require("animatedbg-nvim.canvas").create()
    end

    buf_to_canvas[opts.buffer].setup(opts)

    opts.id = tostring({}):sub(8)
    opts.animation = opts.builder.create(opts)

    global_dt = 1.0 / opts.fps
    local game_loop = internal.get_new_game_loop(opts)
    internal.animations[opts.id] = game_loop
    game_loop.start()

    if not is_execution_running then
      is_execution_running = true
      internal.run()
    end
  end
}


internal.run = function()
  local count = 0
  for _, canvas in pairs(buf_to_canvas) do
    canvas.clear()
  end

  for _, animation in pairs(internal.animations) do
    local opts = animation.get_opts()
    local canvas = buf_to_canvas[opts.buffer]
    animation.loop(global_dt, canvas)
    renderer.render(canvas, opts)
    count = count + 1
  end

  if count > 0 then
    vim.defer_fn(internal.run, global_dt * 1000)
    return
  end

  renderer.clean()
  is_execution_running = false
end

internal.get_new_game_loop = function(opts)
  return {
    start = function()
      opts.animation.init()
    end,
    loop = function(dt, canvas)
      if opts.animation.update(dt) then
        opts.animation.render(canvas)
        return
      else
        internal.animations[opts.id] = nil
      end
    end,
    get_opts = function()
      return opts
    end
  }
end


return M
