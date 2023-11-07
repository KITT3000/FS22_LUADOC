RunState = {}
local RunState_mt = Class(RunState, AbstractState)

function RunState.new(id, stateMachine, scenario, customMt)
	local self = RunState:superClass().new(id, stateMachine, scenario, customMt or RunState_mt)

	return self
end

function RunState:delete()
	RunState:superClass().delete(self)
	self.scenario:delete()
end

function RunState:onEnter()
	RunState:superClass().onEnter(self)
end

function RunState:onExit()
	RunState:superClass().onExit(self)
	self.scenario:complete()
end

function RunState:onUpdate(dt)
	self.scenario:update(dt)

	if self.isServer and self.scenario:isComplete() then
		self.stateMachine:transition(StateIds.BASE_STOP)
	end
end
