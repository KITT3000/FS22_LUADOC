StartState = {}
local StartState_mt = Class(StartState, AbstractState)

function StartState.new(id, stateMachine, scenario, customMt)
	local self = StartState:superClass().new(id, stateMachine, scenario, customMt or StartState_mt)

	return self
end

function StartState:delete()
	StartState:superClass().delete(self)
	self.scenario:delete()
end

function StartState:onEnter()
	StartState:superClass().onEnter(self)
	self.scenario:beforeStart()
end

function StartState:onExit()
	StartState:superClass().onExit(self)
	self.scenario:afterStart()
end

function StartState:onUpdate(dt)
	if self.isServer then
		if self.scenario:canStart() then
			self.scenario:onStart()
			self.stateMachine:transition(StateIds.BASE_RUN)
		else
			self.stateMachine:transition(StateIds.BASE_ABORT)
		end
	end
end
