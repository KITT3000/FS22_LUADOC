StopState = {}
local StopState_mt = Class(StopState, AbstractState)

function StopState.new(id, stateMachine, scenario, customMt)
	local self = StopState:superClass().new(id, stateMachine, scenario, customMt or StopState_mt)

	return self
end

function StopState:delete()
	StopState:superClass().delete(self)
	self.scenario:delete()
end

function StopState:onEnter()
	StopState:superClass().onEnter(self)
	g_messageCenter:subscribe(ScenarioMessageType.SCENARIO_COMPLETED, self.onScenarioCompleted, self)

	if self.isServer and self.scenario:isComplete() and self.scenario.postMessage ~= nil then
		self:onScenarioCompleted(self.scenario.farmId, self.scenario.id)
		g_server:broadcastEvent(ScenarioCompleteEvent.new(self.scenario.farmId, self.scenario.id))
	end
end

function StopState:onExit()
	StopState:superClass().onExit(self)
	g_messageCenter:unsubscribeAll(self)
end

function StopState:onScenarioCompleted(farmId, scenarioId)
	if self.isClient and not g_gui:getIsGuiVisible() and g_currentMission.player.farmId == farmId then
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_INFO,
			text = self.scenario.postMessage
		})
	end
end
