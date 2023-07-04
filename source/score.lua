import "CoreLibs/object"
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics
local WIDTH <const> = 96
local HEIGHT <const> = 22
local SCORE_FORMATTING <const> = "%07d"

class("Score").extends(gfx.sprite)

function Score:init(x, y, value, inverse)
  Score.super.init(self)
  
  self:setImage(gfx.image.new(WIDTH, HEIGHT))
  self.value = value
  self.inverse = inverse
  self:setCenter(0, 0)
  self:moveTo(x, y)
  self:add()
  self:draw()
end

function Score:increment(value)
  self.value = self.value + value
  self:draw()
end

function Score:draw()
  local image = gfx.image.new(self.width, self.height, self.inverse and gfx.kColorBlack or gfx.kColorWhite)
  
  gfx.pushContext(image)
  
  gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  
  gfx.drawTextAligned(
    string.format(SCORE_FORMATTING, self.value),
    self.width,
    0,
    kTextAlignment.right
  )
  
  gfx.popContext()
  
  self:setImage(image)
end