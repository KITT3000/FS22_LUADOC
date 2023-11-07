ScenarioRequestEvent = {}
local ScenarioPendingEvent_mt = Class(ScenarioRequestEvent, Event)

InitEventClass(ScenarioRequestEvent, "ScenarioRequestEvent")

function ScenarioRequestEvent.emptyNew()
	return Event.new(ScenarioPendingEvent_mt)
end

function ScenarioRequestEvent.new(farmId, pool, userId)
	local self = ScenarioRequestEvent.emptyNew()
	self.farmId = farmId
	self.pool = pool
	self.userId = userId or -1

	return self
end

function ScenarioRequestEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteBool(streamId, self.pool ~= nil)

	if self.pool ~= nil then
		streamWriteString(streamId, self.pool)
	end

	streamWriteInt32(streamId, self.userId)
end

function ScenarioRequestEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if streamReadBool(streamId) then
		self.pool = streamReadString(streamId)
	end

	self.userId = streamReadInt32(streamId)

	self:run(connection)
end

function ScenarioRequestEvent:run(connection)
	if not connection:getIsServer() then
		g_messageCenter:publish(ScenarioMessageType.SCENARIO_PENDING, self.farmId, self.pool, self.userId)
	end
end
