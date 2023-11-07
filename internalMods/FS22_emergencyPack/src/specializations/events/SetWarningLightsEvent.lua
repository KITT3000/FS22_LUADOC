SetWarningLightsEvent = {}
local setWarningLightsEvent_event = Class(SetWarningLightsEvent, Event)

InitEventClass(SetWarningLightsEvent, "SetWarningLightsEvent")

function SetWarningLightsEvent.emptyNew()
	local self = Event.new(setWarningLightsEvent_event)

	return self
end

function SetWarningLightsEvent.new(object, state)
	local self = SetWarningLightsEvent.emptyNew()
	self.object = object
	self.state = state

	return self
end

function SetWarningLightsEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function SetWarningLightsEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function SetWarningLightsEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setWarningLightsState(self.state, true)
end

function SetWarningLightsEvent.sendEvent(object, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetWarningLightsEvent.new(object, state), nil, nil, object)
		else
			g_client:getServerConnection():sendEvent(SetWarningLightsEvent.new(object, state))
		end
	end
end
