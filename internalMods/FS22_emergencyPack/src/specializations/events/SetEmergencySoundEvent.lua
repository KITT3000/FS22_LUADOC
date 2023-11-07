SetEmergencySoundEvent = {}
local setWarningLightsEvent_event = Class(SetEmergencySoundEvent, Event)

InitEventClass(SetEmergencySoundEvent, "SetEmergencySoundEvent")

function SetEmergencySoundEvent.emptyNew()
	local self = Event.new(setWarningLightsEvent_event)

	return self
end

function SetEmergencySoundEvent.new(object, index, state)
	local self = SetEmergencySoundEvent.emptyNew()
	self.object = object
	self.index = index
	self.state = state

	return self
end

function SetEmergencySoundEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.index = streamReadUInt8(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function SetEmergencySoundEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUInt8(streamId, self.index)
	streamWriteBool(streamId, self.state)
end

function SetEmergencySoundEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setEmergencySoundStateByIndex(self.index, self.state, true)
end

function SetEmergencySoundEvent.sendEvent(object, index, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetEmergencySoundEvent.new(object, index, state), nil, nil, object)
		else
			g_client:getServerConnection():sendEvent(SetEmergencySoundEvent.new(object, index, state))
		end
	end
end
