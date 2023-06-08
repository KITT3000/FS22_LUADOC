FlowLayoutElement = {}
local FlowLayoutElement_mt = Class(FlowLayoutElement, BoxLayoutElement)

function FlowLayoutElement.new(target, custom_mt)
	local self = FlowLayoutElement:superClass().new(target, custom_mt or FlowLayoutElement_mt)
	self.alignmentX = BoxLayoutElement.ALIGN_LEFT
	self.alignmentY = BoxLayoutElement.ALIGN_BOTTOM

	return self
end

function FlowLayoutElement:invalidateLayout(ignoreVisibility)
	local totalWidth = 0
	local lineHeight = 0

	for _, element in pairs(self.elements) do
		if self:getIsElementIncluded(element, ignoreVisibility) then
			totalWidth = totalWidth + element.absSize[1] + element.margin[1] + element.margin[3]
			lineHeight = math.max(lineHeight, element.absSize[2] + element.margin[2] + element.margin[4])
		end
	end

	local posX = 0
	local currentX = posX
	local currentLine = 0
	local lineLengths = {}

	for currentIndex, element in ipairs(self.elements) do
		if self:getIsElementIncluded(element, ignoreVisibility) then
			local x = currentX + element.margin[1]
			element.line = currentLine

			if x + element.absSize[1] - self.absSize[1] > 0.0001 then
				x = 0
				currentLine = currentLine + 1
				local cutIndex = currentIndex

				for i = currentIndex, 1, -1 do
					local testElement = self.elements[i]

					if (testElement.line ~= nil or i == currentIndex) and not testElement.disallowFlowCut then
						cutIndex = i

						break
					end
				end

				for i = cutIndex, math.max(currentIndex - 1, 1) do
					local moveElement = self.elements[i]

					if moveElement.line ~= nil then
						if i ~= cutIndex then
							x = x + moveElement.margin[1]
						end

						moveElement:setPosition(x, nil)

						moveElement.line = currentLine
						x = x + moveElement.absSize[1] + moveElement.margin[3]
					end
				end

				element.line = currentLine

				if cutIndex ~= currentIndex then
					x = x + element.margin[1]
				end
			end

			element:setPosition(x, nil)

			x = x + element.absSize[1] + element.margin[3]
			currentX = x
			lineLengths[currentLine] = x
		else
			element.line = nil
		end
	end

	local numLines = currentLine + 1
	local totalContentHeight = numLines * lineHeight
	local posY = 0

	if self.alignmentY == FlowLayoutElement.ALIGN_MIDDLE then
		posY = self.absSize[2] * 0.5 - totalContentHeight * 0.5
	elseif self.alignmentY == FlowLayoutElement.ALIGN_TOP then
		posY = self.absSize[2] - totalContentHeight
	end

	for _, element in pairs(self.elements) do
		if element.line ~= nil then
			local y = posY + (numLines - element.line - 1) * lineHeight

			if self.alignmentY == FlowLayoutElement.ALIGN_MIDDLE then
				y = y + math.max(0, (lineHeight - element.absSize[2]) * 0.5)
			elseif self.alignmentY == FlowLayoutElement.ALIGN_TOP then
				y = y + math.max(0, lineHeight - element.absSize[2])
			end

			element:setPosition(nil, y)
		end
	end

	if self.alignmentX == BoxLayoutElement.ALIGN_CENTER or self.alignmentX == BoxLayoutElement.ALIGN_RIGHT then
		for _, element in pairs(self.elements) do
			if lineLengths[element.line] ~= nil then
				local lineLength = lineLengths[element.line]
				local offset = 0
				local size = self.absSize[1]

				if self.alignmentX == BoxLayoutElement.ALIGN_CENTER then
					offset = size / 2 - lineLength / 2
				elseif self.alignmentX == BoxLayoutElement.ALIGN_RIGHT then
					offset = size - lineLength
				end

				local x = element.position[1] + offset

				element:setPosition(x, nil)
			end
		end
	end
end

function FlowLayoutElement:updateAbsolutePosition()
	FlowLayoutElement:superClass().updateAbsolutePosition(self)
	self:invalidateLayout()
end
