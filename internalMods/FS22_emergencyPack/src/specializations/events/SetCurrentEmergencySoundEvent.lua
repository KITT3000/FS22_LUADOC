SetCurrentEmergencySoundEvent = {}
local setWarningLightsEvent_event = Class(SetCurrentEmergencySoundEvent, Event)

InitEventClass(SetCurrentEmergencySoundEvent, "SetCurrentEmergencySoundEvent")

function SetCurrentEmergencySoundEvent.emptyNew()
	local self = Event.new(setWarningLightsEvent_event)

	return self
end

function SetCurrentEmergencySoundEvent.new(object, actionName, index)
	local self = SetCurrentEmergencySoundEvent.emptyNew()
	self.object = object
	self.actionName = actionName
	self.index = index

	return self
end

function SetCurrentEmergencySoundEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.actionName = streamReadString(streamId)
	self.index = streamReadUInt8(streamId)

	self:run(connection)
end

function SetCurrentEmergencySoundEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteString(streamId, self.actionName)
	streamWriteUInt8(streamId, self.index)
end

function SetCurrentEmergencySoundEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setEmergencyGroupCurrentSound(self.actionName, self.index, true)
end

function SetCurrentEmergencySoundEvent.sendEvent(object, actionName, index, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetCurrentEmergencySoundEvent.new(object, actionName, index), nil, nil, object)
		else
			g_client:getServerConnection():sendEvent(SetCurrentEmergencySoundEvent.new(object, actionName, index))
		end
	end
end
