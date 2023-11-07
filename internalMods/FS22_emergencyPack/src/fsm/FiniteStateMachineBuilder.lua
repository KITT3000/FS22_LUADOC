FiniteStateMachineBuilder = {}
local FiniteStateMachineBuilder_mt = Class(FiniteStateMachineBuilder)

function FiniteStateMachineBuilder.new(farmId, isServer)
	local self = {
		farmId = farmId,
		isServer = isServer,
		states = {}
	}

	return setmetatable(self, FiniteStateMachineBuilder_mt)
end

function FiniteStateMachineBuilder:delete()
	self.states = {}
end

function FiniteStateMachineBuilder:stateMachine()
	self.stateMachine = FiniteStateMachine.new(self.farmId, self.isServer)

	return self
end

function FiniteStateMachineBuilder:withScenario(scenario)
	self.scenario = scenario

	return self
end

function FiniteStateMachineBuilder:addInitialState(id, stateRef)
	local state = stateRef.new(id, self.stateMachine, self.scenario)

	return self:withInitialState(id, state)
end

function FiniteStateMachineBuilder:withInitialState(id, state)
	self.stateMachine:setInitialState(state)

	return self:withState(id, state)
end

function FiniteStateMachineBuilder:addState(id, stateRef)
	local state = stateRef.new(id, self.stateMachine, self.scenario)

	return self:withState(id, state)
end

function FiniteStateMachineBuilder:withState(id, state)
	self.states[id] = state

	return self
end

function FiniteStateMachineBuilder:build()
	self.stateMachine:setStates(self.states)
	self.stateMachine:setCurrentState(self.stateMachine:getInitialState())

	return self.stateMachine
end
