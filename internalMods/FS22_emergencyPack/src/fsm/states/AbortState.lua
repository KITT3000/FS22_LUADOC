AbortState = {}
local AbortState_mt = Class(AbortState, AbstractState)

function AbortState.new(id, stateMachine, scenario, customMt)
	local self = AbortState:superClass().new(id, stateMachine, scenario, customMt or AbortState_mt)

	return self
end

function AbortState:delete()
	AbortState:superClass().delete(self)
	self.scenario:delete()
end

function AbortState:onEnter()
	AbortState:superClass().onEnter(self)
	g_messageCenter:subscribe(ScenarioMessageType.SCENARIO_ABORTED, self.onScenarioAborted, self)

	if self.isServer then
		local id = self.scenario.id
		local farmId = self.scenario.farmId
		local reason = self.scenario:getAbortedReason()

		self:onScenarioAborted(farmId, id, reason)
		g_server:broadcastEvent(ScenarioAbortedEvent.new(farmId, id, reason))
	end
end

function AbortState:onExit()
	AbortState:superClass().onExit(self)
	g_messageCenter:unsubscribeAll(self)
end

function AbortState:onScenarioAborted(farmId, scenarioId, reason)
	if self.isClient and not g_gui:getIsGuiVisible() and g_currentMission.player.farmId == farmId then
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_INFO,
			text = g_i18n:getText("info_scenario_aborted"):format(reason)
		})
	end

	if self.isServer then
		g_messageCenter:publish(ScenarioMessageType.SCENARIO_START_STOP, farmId, scenarioId, false, false)
	end
end
