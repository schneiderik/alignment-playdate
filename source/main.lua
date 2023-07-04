import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "helpers"
import "cursor"
import "score"
import "heart"
import "row"
import "gem"

local gfx <const> = playdate.graphics
local HUD_X <const> = 0
local HUD_Y <const> = 0

local MAX_HEALTH <const> = 3
local HEALTH_Y <const> = 8
local HEALTH_X <const> = 8
local HEART_PADDING <const> = 2
local HEART_X_POSITIONS <const> = generate(3, function(i) return HEALTH_X + ((Heart.width + HEART_PADDING) * (i - 1)) end)

local SCORE_X <const> = 296
local SCORE_Y <const> = 8

local STANDARD_TEMPO_INTERVAL <const> = 400
local FAST_TEMPO_INTERVAL <const> = 300

local ROW_BASE_X <const> = 0
local ROW_BASE_Y <const> = 44
local ROW_X <const> = 10
local ROW_Y_POSITIONS <const> = generate(4, function(i) return ROW_BASE_Y + (Row.height * (i - 1)) end)

local STAGE_DIVIDER_START_Y <const> = ROW_BASE_Y
local STAGE_DIVIDER_END_Y <const> = ROW_BASE_Y + (Row.height * 4)
local STAGE_DIVIDER_LINE_WIDTH <const> = 1
local CURSOR_X <const> = 0
local CURSOR_OFFSET_Y <const> = 3
local CURSOR_Y_POSITIONS <const> = generate(3, function(i) return ROW_Y_POSITIONS[i] + CURSOR_OFFSET_Y end)
local CURSOR_INDEX_MIN <const> = 1
local CURSOR_INDEX_MAX <const> = 3

local DEFAULT_QUEUE_SIZE <const> = 2

local GEM_STACK_SCORE_AMOUNT <const> = 10
local GEM_MATCH_SCORE_AMOUNT <const> = 100

local state = {}
local brickImage = gfx.image.new("images/brick")
local fullHeartImage = gfx.image.new("images/heart-full")
local emptyHeartImage = gfx.image.new("images/heart-empty")
local rowBasesImage = gfx.image.new("images/row-bases")

function setupFont()
  local alignmentFont = gfx.font.new("fonts/alignment")
  assert(alignmentFont)
  gfx.setFont(alignmentFont)
end

function setupScreen()
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.clear()
end

function setupState()
	state = {
		view = "battle",
		health = {
			value = MAX_HEALTH,
			sprites = generate(3, function(i) return Heart(HEART_X_POSITIONS[i], HEALTH_Y, true) end),
			set = function(value)
				state.health.value = value
				
				for i = 1, MAX_HEALTH do state.health.sprites[i]:set(i <= value) end
			end,
			decrease = function()
				state.health.set(state.health.value - 1)
			end,
		},
		score = Score(SCORE_X, SCORE_Y, 0),
		tempo = createTempo(STANDARD_TEMPO_INTERVAL),
		cursor = {
			index = CURSOR_INDEX_MIN,
			sprite = Cursor(
		    CURSOR_X,
		    CURSOR_Y_POSITIONS[CURSOR_INDEX_MIN]
		  )
		},
		queueSize = DEFAULT_QUEUE_SIZE,
		rows = generate(
			4, 
			function(i)
				return Row(
					ROW_X,
					ROW_Y_POSITIONS[i],
					{
						onGemStack = function()
							state.score:increment(GEM_STACK_SCORE_AMOUNT)
						end,
						onGemMatch = function()
							state.score:increment(GEM_MATCH_SCORE_AMOUNT)
						end,
						onStackOverflow = function()
							state.health.decrease()
						end
					}
				)
			end
		)
	}
end

function setup()
  setupFont()
  setupScreen()
	setupState()
	
	gfx.sprite.setBackgroundDrawingCallback(
		function(x, y, width, height)
			gfx.setClipRect(x, y, width, height)	
			
			brickImage:draw(
				HUD_X,
				HUD_Y
			)
			
  	  rowBasesImage:draw(
        ROW_BASE_X,
        ROW_BASE_Y
      )
      
		  gfx.setColor(gfx.kColorWhite)
		  gfx.setLineWidth(STAGE_DIVIDER_LINE_WIDTH)
      
		  gfx.drawLine(
        ROW_X + Row.stageOffsetX,
        STAGE_DIVIDER_START_Y,
        ROW_X + Row.stageOffsetX,
        STAGE_DIVIDER_END_Y
      )
      
			gfx.clearClipRect()
		end
	)
end

function handleInput()
	if playdate.buttonJustPressed(playdate.kButtonA) then
		swapRows()
	end
	
	if playdate.buttonJustPressed(playdate.kButtonUp) then
		moveCursor(-1)
	end
	
	if playdate.buttonJustPressed(playdate.kButtonDown) then
		moveCursor(1)
	end
	
	if playdate.buttonIsPressed(playdate.kButtonLeft) then
		setTempo(FAST_TEMPO_INTERVAL)
	end
	
	if playdate.buttonJustReleased(playdate.kButtonLeft) then
		setTempo(STANDARD_TEMPO_INTERVAL)
	end
end

function swapRows()
	local row1 = state.rows[state.cursor.index]
	local row2 = state.rows[state.cursor.index + 1]
	
	row1, row2 = row1:swap(row2)
	
	state.rows[state.cursor.index], state.rows[state.cursor.index + 1] = row2, row1
	state.cursor.sprite:flip()
end

function moveCursor(direction)
	local target = state.cursor.index + direction
	
  if target < CURSOR_INDEX_MIN or target > CURSOR_INDEX_MAX then return end
	
  state.cursor.index = target
	state.cursor.sprite:animateMoveToY(CURSOR_Y_POSITIONS[state.cursor.index])
end

function createTempo(interval)
	return playdate.timer.keyRepeatTimerWithDelay(
    interval,
    interval,
    onTempo
  )
end

function setTempo(interval)
	if state.tempo then state.tempo:remove() end
	
	state.tempo = createTempo(interval)
end

function stageGems()
	local shuffledIndexes = shuffle({1,2,3,4})
	
	for i = 1, state.queueSize do  
    state.rows[shuffledIndexes[i]]:stageGem()
	end
  
  state.queueSize = DEFAULT_QUEUE_SIZE
end

function onTempo()
	if not state.rows then return end
	
	local staged = any(state.rows, function(row) return row.stagedGem ~= nil end)
	local active = any(state.rows, function(row) return row.activeGem ~= nil end)
	local ready = all(state.rows, function(row) return row.ready end)
	
	if not staged and ready then stageGems() end

  if staged and not active then
		each(state.rows, function(row) row:activate() end)
	else
		each(state.rows, function(row) row:onTempo() end)
	end
end

function update()
  for i, row in ipairs(state.rows) do
    row:update()
  end
	
  gfx.sprite.update()
  playdate.timer.updateTimers()
end

function playdate.update()
	handleInput()
	update()
end

setup()
