local classic = require 'classic'
-- Do not install if ALEWrap missing
local hasALEWrap, framework = pcall(require, 'alewrap')
if not hasALEWrap then
  return nil
end

local Rle, super = classic.class('Rle', Env)

-- Constructor
function Rle:_init(opts)
  -- Create ALEWrap options from opts
  opts = opts or {}
  if opts.lifeLossTerminal == nil then
    opts.lifeLossTerminal = true
  end

  local options = {
    game_path = opts.romPath or 'roms',
    core_path = opts.corePath or 'cores',
    core = opts.core or 'snes',
    env = opts.game,
    actrep = opts.actRep or 4,
    random_starts = opts.randomStarts or 1,
    gpu = opts.gpu and opts.gpu - 1 or -1, -- GPU flag (GPU enables faster screen buffer with CudaTensors)
    pool_frms = { -- Defaults to 2-frame mean-pooling
      type = opts.poolFrmsType or 'mean', -- Max captures periodic events e.g. blinking lasers
      size = opts.poolFrmsSize or 2 -- Pools over frames to prevent problems with fixed interval events as above
    },
    env_params = {twoPlayers = opts.twoPlayers or nil}
  }

  -- Use ALEWrap and Rle
  self.gameEnv = framework.GameEnvironment(options)
  -- Create mapping from action index to action for game
  self.actions = self.gameEnv:getActions()
  -- Set evaluation mode by default
  self.trainingFlag = false

  
  -- Life loss = terminal mode
  self.lifeLossTerminal = opts.lifeLossTerminal
end

-- 1 state returned, of type 'real', of dimensionality 3 x 210 x 160, between 0 and 1
function Rle:getStateSpec()
  return {'real', {3, self.ale:getScreenHeight(), self.ale:getScreenWidth()}, {0, 1}}
end

-- 1 action required, of type 'int', of dimensionality 1, between 1 and 18 (max)
function Rle:getActionSpec()
  return {'int', 1, {1, #self.actions}}
end

-- RGB screen of height 224 and width 256
function Rle:getDisplaySpec()
  return {'real', {3, self.ale:getScreenHeight(), self.ale:getScreenWidth()}, {0, 1}}
end

-- Min and max reward (unknown)
function Rle:getRewardSpec()
  return nil, nil
end

-- Starts a new game, possibly with a random number of no-ops
function Rle:start()
  local screen, reward, terminal
  
  if self.gameEnv._random_starts > 0 then
    screen, reward, terminal = self.gameEnv:nextRandomGame()
  else
    screen, reward, terminal = self.gameEnv:newGame()
  end

  return screen:select(1, 1)
end

-- Steps in a game
function Rle:step(actionA, actionB)
  -- Map action index to action for game
  actionA = self.actions[actionA]
  actionB = self.actions[actionB]

  -- Step in the game
  local screen, reward, terminal = self.gameEnv:step(actionA, self.trainingFlag, actionB)

  return reward, screen:select(1, 1), terminal
end

-- Returns display of screen
function Rle:getDisplay()
  return self.gameEnv._state.observation:select(1, 1)
end

-- Set training mode (losing a life triggers terminal signal)
function Rle:training()
  if self.lifeLossTerminal then
    self.trainingFlag = true
  end
end

-- Set evaluation mode (losing lives does not necessarily end an episode)
function Rle:evaluate()
  self.trainingFlag = false
end

return Rle
