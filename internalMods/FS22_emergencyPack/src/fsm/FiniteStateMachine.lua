FiniteStateMachine = {
	EVENT_TRANS = 0,
	EVENT_UPDATE = 1
}
local FiniteStateMachine_mt = Class(FiniteStateMachine)

function FiniteStateMachine.new(farmId, isServer, initialState, states, customMt)
	local self = setmetatable({}, customMt or FiniteStateMachine_mt)
	self.farmId = farmId
	self.isServer = isServer
	self.initialState = initialState
	self.state = initialState
	self.states = states or {}

	return self
end

function FiniteStateMachine:delete()
	if self.state ~= nil then
		self.state:delete()
	end

	self.state = nil
	self.states = {}
end

function FiniteStateMachine:writeStream(streamId, connection)
	local state = self:getCurrentState()

	streamWriteUInt8(streamId, state.id)
end

function FiniteStateMachine:readStream(streamId, connection)
	local stateId = streamReadUInt8(streamId)

	self:transition(stateId, nil, true)
end

function FiniteStateMachine:run(type, toStateId, params, noEventSend)
	if type == FiniteStateMachine.EVENT_TRANS then
		self:transition(toStateId, params, noEventSend)
	elseif type == FiniteStateMachine.EVENT_UPDATE then
		self:requestStateUpdate(noEventSend)
	end
end

function FiniteStateMachine:transition(toStateId, params, noEventSend)
	assert(self.states[toStateId] ~= nil)

	if self.isServer and not noEventSend then
		g_server:broadcastEvent(FiniteStateMachineStateEvent.new(self.farmId, FiniteStateMachine.EVENT_TRANS, toStateId, params), false)
	end

	local nextState = self.states[toStateId]
	local fromState = self.state

	fromState:onExit()
	self:setCurrentState(nextState)
	nextState:onEnter(unpack(params or {}))
end

function FiniteStateMachine:requestStateUpdate(noEventSend)
	if self.isServer and not noEventSend then
		g_server:broadcastEvent(FiniteStateMachineStateEvent.new(self.farmId, FiniteStateMachine.EVENT_UPDATE), false)
	end

	local state = self:getCurrentState()

	if state.updateActions ~= nil then
		for _, action in ipairs(state.updateActions) do
			action(state)
		end
	end
end

function FiniteStateMachine:setCurrentState(state)
	self.state = state
end

function FiniteStateMachine:getCurrentState()
	return self.state
end

function FiniteStateMachine:isInState(id)
	return id == self.state.id
end

function FiniteStateMachine:setInitialState(state)
	self.initialState = state
end

function FiniteStateMachine:getInitialState()
	return self.initialState
end

function FiniteStateMachine:reset()
	local state = self:getInitialState()

	self:transition(state)
end

function FiniteStateMachine:setStates(states)
	self.states = states
end

function FiniteStateMachine:update(dt)
	self.state:onUpdate(dt)
end

function FiniteStateMachine:draw()
	self.state:onDraw()
end
