InRangeActionTool = {
	INTERACTION_DELAY = 2000
}
local InRangeActionTool_mt = Class(InRangeActionTool, RolePlayHandTool)

InitObjectClass(InRangeActionTool, "InRangeActionTool")

function InRangeActionTool.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".inRangeActionTool#inRangeDistance", "The in range distance")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".inRangeActionTool#interactText", "The interaction text")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".inRangeActionTool#actionText", "The action text")
end

function InRangeActionTool.new(isServer, isClient, customMt)
	local self = InRangeActionTool:superClass().new(isServer, isClient, customMt or InRangeActionTool_mt)
	self.interactionDelay = PlacementTool.INTERACTION_DELAY
	self.isInRange = false
	self.inRangeDistance = 2

	return self
end

function InRangeActionTool:postLoad(xmlFile)
	if not InRangeActionTool:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.inRangeDistance = xmlFile:getValue("handTool.inRangeActionTool#inRangeDistance", self.inRangeDistance)
	self.playerInputText = xmlFile:getValue("handTool.inRangeActionTool#interactText", "input_rescueInObject", self.customEnvironment)
	self.playerInputActionText = xmlFile:getValue("handTool.inRangeActionTool#actionText", "input_rescue", self.customEnvironment)

	return true
end

function InRangeActionTool:delete()
	InRangeActionTool:superClass().delete(self)
end

function InRangeActionTool:onActivate(allowInput)
	InRangeActionTool:superClass().onActivate(self, allowInput)

	self.interactionDelay = InRangeActionTool.INTERACTION_DELAY
end

function InRangeActionTool:onDeactivate(allowInput)
	self:doAction(false)

	self.isInRange = false

	if self.isClient then
		self:updateVisual(true)
	end

	InRangeActionTool:superClass().onDeactivate(self, allowInput)
end

function InRangeActionTool:update(dt, allowInput)
	InRangeActionTool:superClass().update(self, dt, allowInput)

	if self.isClient then
		if self.isInRange and self.interactionDelay <= 0 then
			self:setPlayerInputText(self.playerInputActionText)
			self:updateVisual(false)
		else
			self:updateVisual(true)
			self:resetPlayerInputText()
		end
	end

	if self.isActive and allowInput and self.activatePressed and self.isInRange and self.interactionDelay <= 0 then
		self.interactionDelay = InRangeActionTool.INTERACTION_DELAY

		self:doAction(true)
	end

	self.interactionDelay = self.interactionDelay - dt
	self.activatePressed = false
end

function InRangeActionTool:updateTick(dt, allowInput)
	InRangeActionTool:superClass().updateTick(self, dt, allowInput)

	self.isInRange = false
	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return
	end

	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil or not checkpoint.isActive then
		return
	end

	local ref = checkpoint:getObjectReferenceById("object")

	if ref ~= nil then
		local distance = calcDistanceFrom(ref.node, self.handNode)
		self.isInRange = distance < self.inRangeDistance
	else
		self.isInRange = false
	end

	if not self.isServer then
		return
	end

	if self.setAction then
		return
	end

	if self.isActive and self.state then
		checkpoint:setActionCompleted(true)

		self.setAction = true
	end
end

function InRangeActionTool:doAction(state)
	self:setState(state)
end

function InRangeActionTool:updateVisual(doReset)
	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return
	end

	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil or not checkpoint.isActive then
		return
	end

	local ref = checkpoint:getObjectReferenceById("previewObject")

	if ref ~= nil then
		ref.object:setVisibility(not doReset)
	end
end
