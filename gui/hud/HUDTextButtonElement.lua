HUDTextButtonElement = {}
local HUDTextButtonElement_mt = Class(HUDTextButtonElement)

function HUDTextButtonElement.new(posX, posY, width, height, textSize, text, onClickedCallback)
	local self = setmetatable({}, HUDTextButtonElement_mt)
	self.positionX = posX
	self.positionY = posY
	self.width = width
	self.height = height
	self.frameNormalColour = {
		g = 0.0284,
		a = 0.85,
		b = 0.0284,
		r = 0.0284
	}
	self.frameHoveredColour = {
		g = 0.0184,
		a = 0.95,
		b = 0.0184,
		r = 0.0184
	}
	self.frame = Overlay.new(g_baseUIFilename, posX, posY, width, height)

	self.frame:setUVs(g_colorBgUVs)
	self.frame:setColor(self.frameNormalColour.r, self.frameNormalColour.g, self.frameNormalColour.b, self.frameNormalColour.a)

	self.textDisplayOffsetX = width * 0.5
	self.textDisplayOffsetY = height * 0.5 - textSize * 0.5
	self.textDisplay = HUDTextDisplay.new(posX + self.textDisplayOffsetX, posY + self.textDisplayOffsetY, textSize * g_referenceScreenHeight, RenderText.ALIGN_CENTER)

	self.textDisplay:setText(text)

	self.onClickedCallback = onClickedCallback

	return self
end

function HUDTextButtonElement:delete()
	self.frame:delete()
	self.textDisplay:delete()

	self.onClickedCallback = nil
end

function HUDTextButtonElement:setText(text, textSize, textAlignment, textColor, textBold)
	self.textDisplay:setText(text, textSize, textAlignment, textColor, textBold)
end

function HUDTextButtonElement:setPosition(newX, newY)
	self.positionX = newX or self.positionX
	self.positionY = newY or self.positionY

	self.frame:setPosition(self.positionX, self.positionY)
	self.textDisplay:setPosition(self.positionX + self.textDisplayOffsetX, self.positionY + self.textDisplayOffsetY)
end

function HUDTextButtonElement:setFrameColour(r, g, b, a)
	self.frameNormalColour = {
		r = r or self.frameNormalColour.r,
		g = g or self.frameNormalColour.g,
		b = b or self.frameNormalColour.b,
		a = a or self.frameNormalColour.a
	}

	self.frame:setColor(self.frameNormalColour.r, self.frameNormalColour.g, self.frameNormalColour.b, self.frameNormalColour.a)
end

function HUDTextButtonElement:setFrameHoveredColour(r, g, b, a)
	self.frameHoveredColour = {
		r = r or self.frameHoveredColour.r,
		g = g or self.frameHoveredColour.g,
		b = b or self.frameHoveredColour.b,
		a = a or self.frameHoveredColour.a
	}
end

HUDTextButtonElement.setFrameColor = HUDTextButtonElement.setFrameColour
HUDTextButtonElement.setFrameHoveredColor = HUDTextButtonElement.setFrameHoveredColour

function HUDTextButtonElement:draw()
	self.frame:render()
	self.textDisplay:draw()
end

function HUDTextButtonElement:update(dt)
	self.textDisplay:update(dt)
end

function HUDTextButtonElement:mouseEvent(posX, posY, isDown, isUp, button)
	if self.positionX <= posX and posX < self.positionX + self.width and self.positionY <= posY and posY < self.positionY + self.height then
		if isDown and button == Input.MOUSE_BUTTON_LEFT and self.onClickedCallback then
			self.onClickedCallback()
		end

		self.frame:setColor(self.frameHoveredColour.r, self.frameHoveredColour.g, self.frameHoveredColour.b, self.frameHoveredColour.a)
	else
		self.frame:setColor(self.frameNormalColour.r, self.frameNormalColour.g, self.frameNormalColour.b, self.frameNormalColour.a)
	end
end
