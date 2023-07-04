import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics
local HEIGHT <const> = 38
local WIDTH <const> = 32

local gemProperties <const> = {
  Prism = {
	  image = gfx.image.new("images/prism")
  },
  Daimond = {
	  image = gfx.image.new("images/daimond")
  },
  Coin = {
	  image = gfx.image.new("images/coin")
  },
  Ruby = {
	  image = gfx.image.new("images/ruby")
  },
  Opal = {
	  image = gfx.image.new("images/opal")
  }
}

class("Gem").extends(gfx.sprite)

Gem.height = HEIGHT
Gem.width = WIDTH

function Gem.random()
  local gemClasses = {Prism, Daimond, Coin, Ruby, Opal}

  return gemClasses[math.random(#gemClasses)]
end

function Gem:init(x, y)
  Gem.super.init(self)
  
  self:setCenter(0, 0)
  self:moveTo(x, y)
end

for className, properties in pairs(gemProperties) do
  class(className).extends(Gem)
  
  _G[className]["init"] = function (self, x, y)
  	_G[className].super.init(self, x, y)
  	
  	self:setImage(properties["image"])
  end
end

function Gem:pop()
  
end
