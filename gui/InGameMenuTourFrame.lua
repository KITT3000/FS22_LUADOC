InGameMenuTourFrame = {}
local InGameMenuTourFrame_mt = Class(InGameMenuTourFrame, TabbedMenuFrameElement)
InGameMenuTourFrame.CONTROLS = {
	"headerText",
	"contentItem",
	"controlItem",
	"layout"
}

function InGameMenuTourFrame.new(subclass_mt)
	local self = InGameMenuTourFrame:superClass().new(nil, subclass_mt or InGameMenuTourFrame_mt)

	self:registerControls(InGameMenuTourFrame.CONTROLS)

	return self
end

function InGameMenuTourFrame:delete()
	self.contentItem:delete()
	self.controlItem:delete()
	InGameMenuTourFrame:superClass().delete(self)
end

function InGameMenuTourFrame:initialize()
	self.contentItem:unlinkElement()
	self.controlItem:unlinkElement()
end

function InGameMenuTourFrame:onFrameOpen()
	InGameMenuTourFrame:superClass().onFrameOpen(self)
	self:updateContents()
	self.layout:registerActionEvents()
end

function InGameMenuTourFrame:onFrameClose()
	self.layout:removeActionEvents()
	InGameMenuTourFrame:superClass().onFrameClose(self)
end

function InGameMenuTourFrame:updateContents()
	self.headerText:setLocaKey("ui_tour")

	for i = #self.layout.elements, 1, -1 do
		self.layout.elements[i]:delete()
	end

	self.layout:invalidateLayout()

	local steps = g_currentMission.guidedTour:getPassedSteps()

	for index, step in ipairs(steps) do
		local row = self.contentItem:clone(self.layout)
		local textElement = row:getDescendantByName("text")
		local controlsElement = row:getDescendantByName("controls")
		local profile = "tourMenuItem"

		if index == #steps then
			profile = "tourMenuItemCurrent"
		elseif index % 2 == 1 then
			profile = "tourMenuItemAlt"
		end

		row:applyProfile(profile)
		textElement:setText(g_i18n:convertText(step.text))

		local height = textElement:getTextHeight()

		textElement:setSize(nil, height)

		height = height + 60 / g_screenHeight
		local useGamepadButtons = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
		local numVisibleControls = 0

		for _, input in ipairs(step.inputs) do
			local action1 = InputAction[input.action]
			local action2 = input.action2 ~= nil and InputAction[input.action2] or nil

			if (not input.keyboardOnly or not useGamepadButtons) and (not input.gamepadOnly or useGamepadButtons) then
				local controlItem = self.controlItem:clone(controlsElement)
				numVisibleControls = numVisibleControls + 1

				if numVisibleControls == 1 then
					controlItem:applyProfile("tourMenuItemControlsItemFirst")
				end

				local glyph = controlItem:getDescendantByName("glyph")

				glyph:applyProfile("tourMenuItemControlsGlyph")
				glyph:setActions({
					action1,
					action2
				})

				local text = controlItem:getDescendantByName("text")

				text:setText(g_i18n:convertText(input.text))
			end
		end

		controlsElement:setVisible(numVisibleControls > 0)

		if numVisibleControls > 0 then
			controlsElement:setSize(nil, numVisibleControls * controlsElement.elements[1].absSize[2])
			controlsElement:invalidateLayout()

			height = height + controlsElement.absSize[2] + 30 / g_screenHeight
		end

		row:setSize(nil, height)
	end

	self.layout:invalidateLayout()
	self.layout:scrollToEnd()
end
