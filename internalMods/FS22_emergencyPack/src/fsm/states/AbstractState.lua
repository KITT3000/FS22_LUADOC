AbstractState = {}
local AbstractState_mt = Class(AbstractState)

function AbstractState.new(id, stateMachine, scenario, customMt)
	local self = setmetatable({}, customMt or AbstractState_mt)
	self.id = id
	self.isServer = scenario.isServer
	self.isClient = scenario.isClient
	self.stateMachine = stateMachine
	self.scenario = scenario
	self.entryActions = {}
	self.exitActions = {}
	self.updateActions = {}

	return self
end

function AbstractState:delete()
	self.stateMachine = nil
	self.entryActions = {}
	self.exitActions = {}
	self.updateActions = {}
end

function AbstractState:getId()
	return self.id
end

function AbstractState:onEnter(...)
	for _, entryAction in ipairs(self.entryActions) do
		entryAction(self, ...)
	end
end

function AbstractState:onExit(...)
	for _, exitAction in ipairs(self.exitActions) do
		exitAction(self, ...)
	end
end

function AbstractState:onUpdate(dt)
end

function AbstractState:onDraw()
end

function AbstractState:addEntryAction(action)
	table.addElement(self.entryActions, action)
end

function AbstractState:addExitAction(action)
	table.addElement(self.exitActions, action)
end

function AbstractState:addUpdateAction(action)
	table.addElement(self.updateActions, action)
end
