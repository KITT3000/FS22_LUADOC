FireObjectExtinguishedEvent = {}
local FireObjectExtinguishedEvent_mt = Class(FireObjectExtinguishedEvent, Event)

InitEventClass(FireObjectExtinguishedEvent, "FireObjectExtinguishedEvent")

function FireObjectExtinguishedEvent.emptyNew()
	return Event.new(FireObjectExtinguishedEvent_mt)
end

function FireObjectExtinguishedEvent.new(id, fireId)
	local self = FireObjectExtinguishedEvent.emptyNew()
	self.id = id
	self.fireId = fireId

	return self
end

function FireObjectExtinguishedEvent:writeStream(streamId, connection)
	streamWriteInt8(streamId, self.id)
	streamWriteInt32(streamId, self.fireId)
end

function FireObjectExtinguishedEvent:readStream(streamId, connection)
	self.id = streamReadInt8(streamId)
	self.fireId = streamReadInt32(streamId)

	self:run(connection)
end

function FireObjectExtinguishedEvent:run(connection)
	g_messageCenter:publish(ScenarioMessageType.FIRE_EXTINGUISHED, self.id, self.fireId)
end
