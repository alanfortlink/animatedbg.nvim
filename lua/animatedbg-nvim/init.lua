---@diagnostic disable: unused-local
local executor = require("animatedbg-nvim.executor")
local utils = require("animatedbg-nvim.utils")

--- @class Animated
local M = {}

--- @class AnimatedInternal
--- @field animation_builders {string: AnimationBuilder}
--- @field default_opts AnimatedPluginOpts|nil

--- @type AnimatedInternal
local internal = {
  animation_builders = {},
  default_scroll_opts = nil,
}

--- @param builders AnimationBuilder[]
local add_custom_builders = function(builders)
  for _, name in ipairs(builders) do
    local builder = require(name)
    internal.animation_builders[builder.id] = builder
  end
end

local load_builtin_animations = function()
  --- @type string[]
  local builtin = { "animatedbg-nvim.animations.demo", "animatedbg-nvim.animations.fireworks" }
  add_custom_builders(builtin)
end

--- @class Animation
--- @field init fun()
--- @field update fun(dt: number) : boolean
--- @field render fun(canvas: Canvas)

--- @class AnimationBuilder
--- @field id string
--- @field create fun(opts: ExecutorOpts): Animation

--- @class AnimatedPluginOpts
--- @field fps integer | nil
--- @field builders (AnimationBuilder[]) | nil

--- Configured the default options for animations
--- @param opts AnimatedPluginOpts
M.setup = function(opts)
  opts = opts or {}

  opts.fps = opts.fps or 60
  internal.default_opts = opts

  load_builtin_animations()

  if opts.builders then
    add_custom_builders(opts.builders)
  end
end

local ERROR_OPTS_NIL = "`opts` cannot be nil."
local ERROR_NO_ANIMATION = "'%s' animation not found"

--- @class PlayOptions
--- String containing the name of the animation to be played
--- @field animation string


--- Starts the `opts.animation` animation
--- @param opts PlayOptions
M.play = function(opts)
  if not opts then
    error(ERROR_OPTS_NIL);
    return
  end

  if not opts.animation or not internal.animation_builders[opts.animation] then
    error(string.format(ERROR_NO_ANIMATION, opts.animation))
    return
  end

  local builder = internal.animation_builders[opts.animation]
  local executor_opts = {
    builder = builder,
    fps = internal.default_opts.fps,
    buffer = vim.api.nvim_get_current_buf(),
    window = vim.api.nvim_get_current_win(),
  }

  local rows, cols = utils.get_win_size(executor_opts.window)
  executor_opts.rows = rows
  executor_opts.cols = cols

  executor.start_new_animation(executor_opts)
end

return M
