local pdlc_goeweilPackIsLoaded = g_modIsLoaded.pdlc_goeweilPack
local pdlc_vermeerPackIsLoaded = g_modIsLoaded.pdlc_vermeerPack

if pdlc_goeweilPackIsLoaded or pdlc_vermeerPackIsLoaded then
	return
end

StrawHarvestBaleCounterHUDExtension = {
	MOD_DIR = g_currentModDirectory
}
local StrawHarvestBaleCounterHUDExtension_mt = Class(StrawHarvestBaleCounterHUDExtension, VehicleHUDExtension)

function StrawHarvestBaleCounterHUDExtension.new(vehicle, uiScale, uiTextColor, uiTextSize)
	local self = VehicleHUDExtension.new(StrawHarvestBaleCounterHUDExtension_mt, vehicle, uiScale, uiTextColor, uiTextSize)
	self.spec = vehicle.spec_strawHarvestBaleCounter
	self.iconCurrentSquareBales = Utils.getFilename("data/hud/baleCounterTodaySquarebales.png", StrawHarvestBaleCounterHUDExtension.MOD_DIR)
	self.iconLifeTimeSquareBales = Utils.getFilename("data/hud/baleCounterLifetimeSquarebales.png", StrawHarvestBaleCounterHUDExtension.MOD_DIR)
	self.iconCurrentRoundBales = Utils.getFilename("data/hud/baleCounterTodayRoundbales.png", StrawHarvestBaleCounterHUDExtension.MOD_DIR)
	self.iconLifeTimeRoundBales = Utils.getFilename("data/hud/baleCounterLifetimeRoundbales.png", StrawHarvestBaleCounterHUDExtension.MOD_DIR)
	local _, displayHeight = getNormalizedScreenValues(0, 41 * uiScale)
	local _, textSize = getNormalizedScreenValues(0, 20 * uiScale)
	self.displayHeight = displayHeight
	self.textSize = textSize
	self.countOverlayX = getNormalizedScreenValues(27 * uiScale, 0)
	self.countTextX = getNormalizedScreenValues(80 * uiScale, 0)
	self.lifetimeOverlayX = getNormalizedScreenValues(148 * uiScale, 0)
	self.lifetimeTextX = getNormalizedScreenValues(201 * uiScale, 0)
	local width, height = getNormalizedScreenValues(40 * uiScale, 40 * uiScale)
	self.countOverlay = Overlay.new(self.iconCurrentSquareBales, 0, 0, width, height)

	self.countOverlay:setUVs(GuiUtils.getUVs(StrawHarvestBaleCounterHUDExtension.UV, StrawHarvestBaleCounterHUDExtension.SIZE))
	self.countOverlay:setColor(unpack(StrawHarvestBaleCounterHUDExtension.COLOR))

	self.lifetimeOverlay = Overlay.new(self.iconLifeTimeSquareBales, 0, 0, width, height)

	self.lifetimeOverlay:setUVs(GuiUtils.getUVs(StrawHarvestBaleCounterHUDExtension.UV, StrawHarvestBaleCounterHUDExtension.SIZE))
	self.lifetimeOverlay:setColor(unpack(StrawHarvestBaleCounterHUDExtension.COLOR))

	local isRoundBaler = vehicle:isRoundBaler()

	self.countOverlay:setImage(isRoundBaler and self.iconCurrentRoundBales or self.iconCurrentSquareBales)
	self.lifetimeOverlay:setImage(isRoundBaler and self.iconLifeTimeRoundBales or self.iconLifeTimeSquareBales)
	self:addComponentForCleanup(self.countOverlay)
	self:addComponentForCleanup(self.lifetimeOverlay)

	return self
end

function StrawHarvestBaleCounterHUDExtension:getPriority()
	return 1
end

function StrawHarvestBaleCounterHUDExtension:canDraw()
	return true
end

function StrawHarvestBaleCounterHUDExtension:getDisplayHeight()
	return self:canDraw() and self.displayHeight or 0
end

function StrawHarvestBaleCounterHUDExtension:getHelpEntryCountReduction()
	return self:canDraw() and 1 or 0
end

function StrawHarvestBaleCounterHUDExtension:draw(leftPosX, rightPosX, posY)
	if not self:canDraw() then
		return
	end

	self.countOverlay:setPosition(leftPosX + self.countOverlayX - self.countOverlay.width * 0.5, posY + self.displayHeight * 0.5 - self.countOverlay.height * 0.5)
	self.lifetimeOverlay:setPosition(leftPosX + self.lifetimeOverlayX - self.lifetimeOverlay.width * 0.5, posY + self.displayHeight * 0.5 - self.lifetimeOverlay.height * 0.5)
	self.countOverlay:render()
	self.lifetimeOverlay:render()
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	setTextColor(1, 1, 1, 1)
	renderText(leftPosX + self.countTextX, posY + self.displayHeight * 0.55, self.textSize, ("%d"):format(self.spec.currentCount))
	renderText(leftPosX + self.lifetimeTextX, posY + self.displayHeight * 0.55, self.textSize, ("%d"):format(self.spec.lifetimeCount))
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)

	return posY
end

StrawHarvestBaleCounterHUDExtension.COLOR = {
	1,
	1,
	1,
	1
}
StrawHarvestBaleCounterHUDExtension.SIZE = {
	64,
	64
}
StrawHarvestBaleCounterHUDExtension.UV = {
	0,
	1,
	64,
	64
}
