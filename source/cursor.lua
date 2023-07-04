import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/easing"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local easing <const> = playdate.easingFunctions
local STATIC_FRAME <const> = 1
local FLIP_ANIMATION_SPEED <const> = 20
local MOVEMENT_ANIMATION_SPEED <const> = 200

class("Cursor").extends(gfx.sprite)

function Cursor:init(x, y)
  Cursor.super.init(self)
  
  self.images = gfx.imagetable.new("images/cursor")
  self.flipAnimator = nil
  
  self:setImage(self.staticImage)
  self:setCenter(0, 0)
  self:moveTo(x, y)
  self:add()
end

function Cursor:flip()
  local startFrame = self:getFlipFrame()
  local endFrame = self:getFlipEndFrame()
  
  self.flipAnimator = gfx.animator.new(
    FLIP_ANIMATION_SPEED * math.abs(endFrame - startFrame),
    startFrame,
    endFrame
  )
end

function Cursor:getFlipFrame()
  if self.flipAnimator then
    return math.tointeger(math.ceil(self.flipAnimator:currentValue()))
  else
    return STATIC_FRAME
  end
end

function Cursor:getFlipEndFrame()
  if self.flipAnimator and self.flipAnimator.endValue ~= STATIC_FRAME then
    return STATIC_FRAME
  else
    return #self.images 
  end
end

function Cursor:animateMoveToY(y)
  self.movementAnimator = gfx.animator.new(
    MOVEMENT_ANIMATION_SPEED,
    self.y,
    y,
    easing.outCubic
  )
end

function Cursor:update()
  self:setImage(self.images:getImage(self:getFlipFrame()))
  
  if self.flipAnimator and self.flipAnimator:ended() then self.flipAnimator = nil end

  if self.movementAnimator and not self.movementAnimator:ended() then
  	self:moveTo(self.x, self.movementAnimator:currentValue())
	end
end
