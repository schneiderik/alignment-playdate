import "CoreLibs/object"
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics
local WIDTH = 23
local HEIGHT = 22

class("Heart").extends(gfx.sprite)

Heart.width = WIDTH
Heart.height = HEIGHT

function Heart:init(x, y, value)
  Score.super.init(self)
  
  self.value = value ~= nil and value or true
  
  self.fullImage = gfx.image.new("images/heart-full")
  self.emptyImage = gfx.image.new("images/heart-empty")
  
  self:setImage(value and self.fullImage or self.emptyImage)
  self:setCenter(0, 0)
  self:moveTo(x, y)
  self:add()
end

function Heart:set(value)
  self.value = value
  
  self:setImage(self.value and self.fullImage or self.emptyImage)
end