PlaceObjectAction = {
	OBJECT_ID = "placement"
}
local PlaceObjectAction_mt = Class(PlaceObjectAction, CompletableHandToolAction)

function PlaceObjectAction.new(checkpoint)
	return PlaceObjectAction:superClass().new(checkpoint, PlaceObjectAction_mt)
end

function PlaceObjectAction:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode)
	if not PlaceObjectAction:superClass().loadFromXML(self, xmlFile, baseKey, baseDirectory, rootNode) then
		return false
	end

	self.amountToPlace = xmlFile:getInt(baseKey .. "#amountOfObjectsToPlace", 5)

	return true
end

function PlaceObjectAction:getAmountToPlace()
	return self.amountToPlace
end

function PlaceObjectAction:onStart()
	PlaceObjectAction:superClass().onStart(self)
	g_messageCenter:subscribe(ScenarioMessageType.OBJECT_PLACED, self.onObjectPlaced, self)
end

function PlaceObjectAction:onComplete()
	PlaceObjectAction:superClass().onComplete(self)
	g_messageCenter:unsubscribeAll(self)
end

function PlaceObjectAction:onObjectPlaced(scenarioId)
	local scenario = self.checkpoint:getScenario()

	if scenario == nil or scenario.id ~= scenarioId then
		return
	end

	local numberOfObjects = scenario:getNumberOfObjectsWithId(PlaceObjectAction.OBJECT_ID)

	if self.amountToPlace <= numberOfObjects then
		self.checkpoint:setActionCompleted(true)
	end
end
