FiniteStateMachineStateEvent = {}
local FiniteStateMachineStateEvent_mt = Class(FiniteStateMachineStateEvent, Event)

InitEventClass(FiniteStateMachineStateEvent, "FiniteStateMachineStateEvent")

function FiniteStateMachineStateEvent.emptyNew()
	local self = Event.new(FiniteStateMachineStateEvent_mt)

	return self
end

function FiniteStateMachineStateEvent.new(farmId, type, stateId, params)
	local self = FiniteStateMachineStateEvent.emptyNew()
	self.farmId = farmId
	self.type = type
	self.stateId = stateId
	self.params = params or {}

	return self
end

function FiniteStateMachineStateEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.type, 2)

	if self.type ~= FiniteStateMachine.EVENT_UPDATE then
		streamWriteUInt8(streamId, self.stateId)
		streamWriteUInt8(streamId, #self.params)

		for _, param in ipairs(self.params) do
			assert(type(param) == "number")
			streamWriteInt32(streamId, param)
		end
	end
end

function FiniteStateMachineStateEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.type = streamReadUIntN(streamId, 2)

	if self.type ~= FiniteStateMachine.EVENT_UPDATE then
		self.stateId = streamReadUInt8(streamId)
		local numOfParams = streamReadUInt8(streamId)

		if numOfParams > 0 then
			self.params = {}

			for i = 1, numOfParams do
				table.insert(self.params, streamReadInt32(streamId))
			end
		else
			self.params = {}
		end
	end

	self:run(connection)
end

function FiniteStateMachineStateEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.STATEMACHINE_TRANSITION, self.farmId, self.type, self.stateId, self.params)
end
