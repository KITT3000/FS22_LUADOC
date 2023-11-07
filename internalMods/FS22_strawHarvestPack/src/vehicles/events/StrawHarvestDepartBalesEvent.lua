StrawHarvestDepartBalesEvent = {}
local StrawHarvestDepartBalesEvent_mt = Class(StrawHarvestDepartBalesEvent, Event)

InitEventClass(StrawHarvestDepartBalesEvent, "StrawHarvestDepartBalesEvent")

function StrawHarvestDepartBalesEvent.emptyNew()
	local self = Event.new(StrawHarvestDepartBalesEvent_mt)

	return self
end

function StrawHarvestDepartBalesEvent.new(object, triggerDepart, doDepart)
	local self = StrawHarvestDepartBalesEvent.emptyNew()
	self.object = object
	self.triggerDepart = triggerDepart
	self.doDepart = doDepart

	return self
end

function StrawHarvestDepartBalesEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.triggerDepart = streamReadBool(streamId)
	self.doDepart = streamReadBool(streamId)

	self:run(connection)
end

function StrawHarvestDepartBalesEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.triggerDepart)
	streamWriteBool(streamId, self.doDepart)
end

function StrawHarvestDepartBalesEvent:run(connection)
	if self.triggerDepart then
		if not connection:getIsServer() then
			g_server:broadcastEvent(self, false, connection, self.object)
		end

		self.object:setDepartBales(self.triggerDepart, self.doDepart, true)
	elseif self.doDepart then
		self.object:departBales()
	end
end

function StrawHarvestDepartBalesEvent.sendEvent(object, triggerDepart, doDepart, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(StrawHarvestDepartBalesEvent.new(object, triggerDepart, doDepart), nil, nil, object)
		else
			g_client:getServerConnection():sendEvent(StrawHarvestDepartBalesEvent.new(object, triggerDepart, doDepart))
		end
	end
end
