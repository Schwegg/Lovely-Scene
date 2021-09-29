lovelyScene = require 'lovely-scene'
-- -- --
exampleBoolean = false
local player = {direction="right"}
-- -- --
function love.load()
  lovelyScene:setActorSearchFunc( actorSearchFunc )
  
  -- sets current specified actor's variable 'direction' to given direction
  -- eg. 'setDir left' sets 'actor.direction = "left"' with 'left' being a string
  lovelyScene:newKeyword( "setDir", function( command ) command.actor.direction = command.vars[1] end )
  
  lovelyScene:loadScene( "exampleScene" )
end
-- -- --
function love.update( dt )
end
-- -- --
function love.draw()
end
-- -- --


-- -- --
function getPlayer() return player end
-- -- --
function actorSearchFunc( name )
  if name == "Player" then
    return player
  end
end
