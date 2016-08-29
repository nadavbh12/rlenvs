local image = require 'image'
local Rle = require 'rlenvs/Rle'

-- Detect QT for image display
local qt = pcall(require, 'qt')

-- Initialise and start environment
local opts = {}
opts.romPath="/home/administrator/DQN/roms/"
opts.corePath="/home/administrator/DQN/tempDQN/Arcade-Learning-Environment-2.0/snes9x-next/"
opts.gpu=0
opts.core="snes"
opts.game="mortal_kombat.sfc"
local env = Rle(opts)
local stateSpec = env:getStateSpec()
local actionSpec = env:getActionSpec()
local observation = env:start()

local reward, terminal
local episodes, totalReward = 0, 0
local nSteps = 1000 * (stateSpec[2][2] - 1) -- Run for 1000 episodes

-- Display
local window = qt and image.display({image=observation, zoom=10})

for i = 1, nSteps do
  -- Pick random action and execute it
  local action = torch.random(actionSpec[3][1], actionSpec[3][2])
  reward, observation, terminal = env:step(action)
  totalReward = totalReward + reward

  -- Display
  if qt then
    image.display({image=observation, zoom=10, win=window})
  end

  -- If game finished, start again
  if terminal then
    episodes = episodes + 1
    observation = env:start()
  end
end
print('Episodes: ' .. episodes)
print('Total Reward: ' .. totalReward)
