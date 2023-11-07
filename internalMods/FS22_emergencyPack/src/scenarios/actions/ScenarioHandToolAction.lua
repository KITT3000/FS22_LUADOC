ScenarioHandToolAction = {}
local ScenarioHandToolAction_mt = Class(ScenarioHandToolAction, ScenarioAction)

function ScenarioHandToolAction.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresHandTool", "Action requires a hand tool")
	schema:register(XMLValueType.BOOL, basePath .. "#canCycleHandTool", "The player can cycle hand tool")
	schema:register(XMLValueType.STRING, basePath .. ".handTool#filename", "Hand tool xml filename")
end

function ScenarioHandToolAction.new(checkpoint, custom_mt)
	local self = ScenarioHandToolAction:superClass().new(checkpoint, custom_mt or ScenarioHandToolAction_mt)
	self.requiresHandTool = false
	self.handToolFilename = nil
	self.currentPlayer = nil
	self.handToolIsLost = false

	return self
end

function ScenarioHandToolAction:delete()
	local player = g_currentMission.player

	if player ~= nil then
		self:unEquipHandTool(player)

		self.currentPlayer = nil
	end

	ScenarioHandToolAction:superClass().delete(self)
end

function ScenarioHandToolAction:onUpdate(dt)
	ScenarioHandToolAction:superClass().onUpdate(self, dt)

	if self.handToolIsLost and not self.canCycleHandTool and g_currentMission.controlPlayer and g_currentMission.controlledVehicle == nil then
		local farmId = self.checkpoint:getFarmId()
		local player = g_currentMission.player

		if player ~= nil and player.farmId == farmId and not player:hasHandtoolEquipped() and self.checkpoint:isInRangeOfNode(player.rootNode) then
			self:equipHandTool(player)
		end
	end
end

function ScenarioHandToolAction:setIsActive(isActive)
	ScenarioHandToolAction:superClass().setIsActive(self, isActive)

	local farmId = self.checkpoint:getFarmId()
	local player = g_currentMission.player

	if isActive then
		if player ~= nil and player.farmId == farmId then
			g_farmManager:getFarmById(player.farmId):addHandTool(self.handToolFilename)

			if self.checkpoint:isInRangeOfNode(player.rootNode) then
				self:equipHandTool(player)
			else
				self.handToolIsLost = true
			end
		end
	elseif player ~= nil and player.farmId == farmId then
		g_farmManager:getFarmById(player.farmId):removeHandTool(self.handToolFilename)
		self:unEquipHandTool(player)

		self.currentPlayer = nil
	end
end

function ScenarioHandToolAction:equipHandTool(player)
	self.currentPlayer = player
	self.handToolIsLost = false

	player:pickUpObject(false)
	player:addDeleteListener(self, "onPlayerDeleted")
	player:equipHandtool(self.handToolFilename, true, nil, self.onHandToolEquipped, self)
end

function ScenarioHandToolAction:unEquipHandTool(player)
	if player:hasHandtoolEquipped() then
		local handTool = player.baseInformation.currentHandtool

		handTool:removeDeleteListener(self, "onHandToolDeleted")
		player:unequipHandtool()
	end

	player:removeDeleteListener(self, "onPlayerDeleted")
end

function ScenarioHandToolAction:onHandToolEquipped(handTool)
	handTool:addDeleteListener(self, "onHandToolDeleted")
end

function ScenarioHandToolAction:onHandToolDeleted()
	self.currentPlayer = nil
	self.handToolIsLost = true
end

function ScenarioHandToolAction:onPlayerDeleted(player)
	if player == self.currentPlayer then
		self.currentPlayer = nil
	end
end

function ScenarioHandToolAction:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode)
	if not ScenarioHandToolAction:superClass().loadFromXML(self, xmlFile, baseKey, baseDirectory, rootNode) then
		return false
	end

	self.canCycleHandTool = xmlFile:getValue(baseKey .. "#canCycleHandTool", true)
	self.requiresHandTool = xmlFile:getValue(baseKey .. "#requiresHandTool", false)

	if self.requiresHandTool then
		local filename = xmlFile:getValue(baseKey .. ".handTool#filename")
		self.handToolFilename = Utils.getFilename(filename, baseDirectory)

		if not fileExists(self.handToolFilename) then
			self.handToolFilename = Utils.getFilename(filename, g_currentMission.rolePlay.modDirectory)
		end
	end

	return true
end

function ScenarioHandToolAction:canBeCompleted()
	return false
end
