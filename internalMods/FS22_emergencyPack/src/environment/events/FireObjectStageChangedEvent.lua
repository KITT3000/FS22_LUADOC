FireObjectStageChangedEvent = {}
local FireObjectStageChangedEvent_mt = Class(FireObjectStageChangedEvent, Event)

InitEventClass(FireObjectStageChangedEvent, "FireObjectStageChangedEvent")

function FireObjectStageChangedEvent.emptyNew()
	return Event.new(FireObjectStageChangedEvent_mt)
end

function FireObjectStageChangedEvent.new(id, fireId, stage)
	local self = FireObjectStageChangedEvent.emptyNew()
	self.id = id
	self.fireId = fireId
	self.stage = stage

	return self
end

function FireObjectStageChangedEvent:writeStream(streamId, connection)
	streamWriteInt8(streamId, self.id)
	streamWriteInt32(streamId, self.fireId)
	streamWriteInt8(streamId, self.stage)
end

function FireObjectStageChangedEvent:readStream(streamId, connection)
	self.id = streamReadInt8(streamId)
	self.fireId = streamReadInt32(streamId)
	self.stage = streamReadInt8(streamId)

	self:run(connection)
end

function FireObjectStageChangedEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.FIRE_STAGE_UPDATE, self.id, self.fireId, self.stage)
end
