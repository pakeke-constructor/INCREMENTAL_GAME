# AutoAtlas
lightweight automatic sprite atlas constructor, using leafi's 2d packer.
Thanks github.com/speakk & AimeJohnson for all the great help!

### Construction:

Can create as many atlases as you want, however 1 atlas is most efficient.
```lua
local AutoAtlas = require "atlas_path/AutoAtlas.lua"

local atlas = AutoAtlas(2000, 2000)    
-- Creates new atlas, of size 2000 * 2000 pixels.
--default size is 2048 * 2048
```


### Usage:
```lua

local imageData = love.image.newImageData("sprites/animals/monkey.png")

local monkey = atlas:add(imageData)  -- Adds to atlas
-- (monkey is a love2d quad)


function love.draw()
  atlas:draw(monkey, 20, 50 )   -- supports all args from lg.draw
  
  -- or, equivalently:
  love.graphics.draw( atlas.image, monkey, 20, 50 )

end
```
And thats it!
That is everything you need to know.

