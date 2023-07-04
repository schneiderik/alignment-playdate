import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "gem"
import "helpers"

local gfx <const> = playdate.graphics

local HEIGHT <const> = Gem.height
local MAX_GEMS <const> = 7
local STAGE_HORIZONTAL_PADDING <const> = 2
local STAGE_OFFSET_X <const> = STAGE_HORIZONTAL_PADDING + (Gem.width * MAX_GEMS)
local THRESHOLD_X <const> = Gem.width * (MAX_GEMS - 1) + 1
local ACTIVE_GEM_MOVEMENT_INCREMENT <const> = -Gem.width/2
local ACTIVE_GEM_START_OFFSET_X <const> = (Gem.width * MAX_GEMS) - (Gem.width / 2) + 1

local FLIP_ANIMATION_DURATION <const> = 200

class("Row").extends()

Row.height = HEIGHT
Row.maxGems = MAX_GEMS
Row.stageOffsetX = STAGE_OFFSET_X

function Row:init(x, y, callbacks)
  self.x = x
  self.y = y
  self.targetY = y
  self.ready = true
  self.activeGem = nil
  self.stagedGem = nil
  self.stack = {}
  self.callbacks = callbacks or {}
end

function Row:activate()
  if not self.stagedGem then return end
  
  self.activeGem = self.stagedGem
  self.stagedGem = nil
  
  self.activeGem:moveTo(
    self.x + ACTIVE_GEM_START_OFFSET_X,
    self.y
  )
end

function Row:getStageX()
  return self.x + STAGE_OFFSET_X
end

function Row:getStagedGemX()
  return self.x + STAGE_OFFSET_X + STAGE_HORIZONTAL_PADDING
end

function Row:stageGem()
  if self.stagedGem then return end
  
  self.ready = false
  
	self.stagedGem = (Gem.random())(
	  self:getStagedGemX(),
    self.y
	)

  self.stagedGem:add()
end

function Row:moveActiveGem()
  if not self.activeGem then return end
  
  self.activeGem:moveBy(ACTIVE_GEM_MOVEMENT_INCREMENT, 0)
        
  if self.activeGem.x <= self.x + THRESHOLD_X then
    self.ready = true
  end
end

function Row:stackGem(gem)
  gem:moveTo(
    self:getStackEndX(),
    self.y
  )
  
  table.insert(self.stack, gem)
end

function Row:stackActiveGem()
  self:stackGem(self.activeGem)
  
  self.activeGem = nil
  
  if self.callbacks.onGemStack then self.callbacks.onGemStack() end
end

function Row:getStackEndX()
  return self.x + (#self.stack * Gem.width) + 1
end

function Row:getLastGem()
  return self.stack[#self.stack]
end

function Row:removeGem(index)
  self.stack[index]:remove()
  table.remove(self.stack, index)
end

function Row:removeLastGem()
  self:removeGem(#self.stack)
end

function Row:gemsMatch(gem1, gem2)
  return getmetatable(gem1) == getmetatable(gem2)
end

function Row:popLastGem()
  self:getLastGem():pop()
  self:removeLastGem()
end

function Row:popActiveGem()
  self.activeGem:pop()
  self.activeGem:remove()
  self.activeGem = nil
end

function Row:update()
  if self.moveToYAnimator and not self.moveToYAnimator:ended() then
    self.y = self.moveToYAnimator:currentValue()
    
    for i, gem in ipairs(self.stack) do
      gem:moveTo(gem.x, self.y)
    end
    
    if self.activeGem and self.activeGem.y ~= self.moveToYAnimator.endValue then
      self.activeGem:moveTo(self.activeGem.x, self.y)
    end
  end
end

function Row:swap(other)
	local activeGemFree = self.activeGem and self.activeGem.x > other:getStackEndX()
	local otherActiveGemFree = other.activeGem and other.activeGem.x > self:getStackEndX()
	
	if activeGemFree or otherActiveGemFree then
		self.activeGem, other.activeGem = other.activeGem, self.activeGem
	end
	
	self.ready, other.ready = other.ready, self.ready
	self.stagedGem, other.stagedGem = other.stagedGem, self.stagedGem
	
  local y1 = (self.moveToYAnimator and not self.moveToYAnimator:ended()) and self.moveToYAnimator.startValue or self.y
  local y2 = (other.moveToYAnimator and not other.moveToYAnimator:ended()) and other.moveToYAnimator.startValue or other.y
  
	self:animateMoveToY(FLIP_ANIMATION_DURATION, y2)
	other:animateMoveToY(FLIP_ANIMATION_DURATION, y1)
  
  return self, other
end

function Row:onTempo()
  if not self.activeGem then return end
  
  self:moveActiveGem()
    
  if self.activeGem.x <= self:getStackEndX() then
    self.ready = true

    if #self.stack and self:gemsMatch(self:getLastGem(), self.activeGem) then
      self:popLastGem()
      self:popActiveGem()
      
      if self.callbacks.onGemMatch then self.callbacks.onGemMatch() end
    else
      self:stackActiveGem()
      
      if #self.stack > MAX_GEMS then
        each(self.stack, function (gem) gem:remove() end)
        self.stack  = {}
        
        if self.callbacks.onStackOverflow then self.callbacks.onStackOverflow() end
      end
    end
  end
end

function Row:animateMoveToY(duration, y)
  self.moveToYAnimator = gfx.animator.new(duration, self.y, y)
end

