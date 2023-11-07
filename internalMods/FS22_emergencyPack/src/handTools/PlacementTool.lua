PlacementTool = {
	INTERACTION_DELAY = 2000
}
local PlacementTool_mt = Class(PlacementTool, RolePlayHandTool)

InitObjectClass(PlacementTool, "PlacementTool")

function PlacementTool.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".placementTool#filename", "The i3d object to place")
	schema:register(XMLValueType.INT, basePath .. ".placementTool#index", "The i3d object index to place")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".placementTool#offset", "Placement offset vector from player root")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".placementTool.sounds", "drop")
end

function PlacementTool.new(isServer, isClient, customMt)
	local self = PlacementTool:superClass().new(isServer, isClient, customMt or PlacementTool_mt)
	self.playerInputText = g_i18n:getText("input_placeMarker")
	self.interactionDelay = PlacementTool.INTERACTION_DELAY
	self.numberOfObjectsPlaced = 0

	return self
end

function PlacementTool:postLoad(xmlFile)
	if not PlacementTool:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.objectFilename = xmlFile:getValue("handTool.placementTool#filename", "data/objects/cones/cones.i3d")
	self.objectIndex = xmlFile:getValue("handTool.placementTool#index", 0)
	self.placementOffset = xmlFile:getValue("handTool.placementTool#offset", "0 0 1", true)
	self.sample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.placementTool.sounds", "drop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)

	return true
end

function PlacementTool:delete()
	g_soundManager:deleteSample(self.sample)
	PlacementTool:superClass().delete(self)
end

function PlacementTool:onActivate(allowInput)
	PlacementTool:superClass().onActivate(self, allowInput)

	self.interactionDelay = PlacementTool.INTERACTION_DELAY
	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return
	end

	local numberOfObjectsPlaced = scenario:getNumberOfObjectsWithId(PlaceObjectAction.OBJECT_ID)
	self.numberOfObjectsPlaced = numberOfObjectsPlaced
end

function PlacementTool:onDeactivate(allowInput)
	PlacementTool:superClass().onDeactivate(self, allowInput)
end

function PlacementTool:update(dt, allowInput)
	PlacementTool:superClass().update(self, dt, allowInput)

	if self.isActive and allowInput then
		local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

		if scenario == nil then
			return
		end

		local inRange, distance = scenario:isInRangeOfNode(self.player.rootNode)

		if inRange then
			if self.activatePressed and self.interactionDelay <= 0 then
				self:placeObject()

				self.interactionDelay = PlacementTool.INTERACTION_DELAY
			end
		elseif self.player == g_currentMission.player then
			g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_rangeRestriction"), distance), 100)
		end
	end

	self.interactionDelay = self.interactionDelay - dt
	self.activatePressed = false
end

function PlacementTool:updateTick(dt, allowInput)
	PlacementTool:superClass().updateTick(self, dt, allowInput)
end

function PlacementTool:setState(state, noEventSend)
	PlacementTool:superClass().setState(self, state, noEventSend)

	if self.isServer then
		local x, y, z = getWorldTranslation(self.currentPlayerHandNode)
		local offsetX, offsetY, offsetZ = unpack(self.placementOffset)
		local dx, _, dz = localDirectionToWorld(self.currentPlayerHandNode, offsetX, offsetY, offsetZ)
		x = x - dx
		z = z - dz
		local rotY = math.atan2(dx, dz)
		local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

		g_messageCenter:publish(ScenarioMessageType.OBJECT_PLACED, scenario.id, PlaceObjectAction.OBJECT_ID, self.objectFilename, self.objectIndex, x, y, z, rotY)
		g_server:broadcastEvent(ScenarioObjectAtWorldPositionEvent.new(scenario.id, PlaceObjectAction.OBJECT_ID, self.objectFilename, self.objectIndex, x, y, z, rotY), false)
	end

	self.numberOfObjectsPlaced = self.numberOfObjectsPlaced + 1

	if self.isClient then
		g_soundManager:playSample(self.sample)
	end
end

function PlacementTool:placeObject()
	self:setState(true)
end
