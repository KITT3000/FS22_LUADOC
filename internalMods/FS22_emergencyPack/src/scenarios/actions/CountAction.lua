CountAction = {
	OBJECT_ID = "count"
}
local CountAction_mt = Class(CountAction, CompletableHandToolAction)

function CountAction.new(checkpoint)
	local self = CountAction:superClass().new(checkpoint, CountAction_mt)
	self.count = 0

	return self
end

function CountAction:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode)
	if not CountAction:superClass().loadFromXML(self, xmlFile, baseKey, baseDirectory, rootNode) then
		return false
	end

	self.amountToCount = xmlFile:getInt(baseKey .. "#amountToCount", 5)

	return true
end

function CountAction:getAmountToCount()
	return self.amountToCount
end

function CountAction:getCount()
	return self.count
end

function CountAction:onStart()
	CountAction:superClass().onStart(self)
	g_messageCenter:subscribe(ScenarioMessageType.SCENARIO_CHECKPOINT_ACTION_COUNT, self.onCount, self)
end

function CountAction:onComplete()
	CountAction:superClass().onComplete(self)
	g_messageCenter:unsubscribeAll(self)
end

function CountAction:onCount(scenarioId)
	local scenario = self.checkpoint:getScenario()

	if scenario == nil or scenario.id ~= scenarioId then
		return
	end

	self.count = self.count + 1

	if self.amountToCount <= self.count then
		self.checkpoint:setActionCompleted(true)
	end
end
