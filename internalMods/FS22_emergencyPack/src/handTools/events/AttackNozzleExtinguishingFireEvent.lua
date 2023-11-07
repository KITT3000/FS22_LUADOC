AttackNozzleExtinguishingFireEvent = {}
local AttackNozzleExtinguishingFireEvent_mt = Class(AttackNozzleExtinguishingFireEvent, Event)

InitEventClass(AttackNozzleExtinguishingFireEvent, "AttackNozzleExtinguishingFireEvent")

function AttackNozzleExtinguishingFireEvent.emptyNew()
	local self = Event.new(AttackNozzleExtinguishingFireEvent_mt)

	return self
end

function AttackNozzleExtinguishingFireEvent.new(player, isExtinguishingFire)
	local self = AttackNozzleExtinguishingFireEvent.emptyNew()
	self.player = player
	self.isExtinguishingFire = isExtinguishingFire

	return self
end

function AttackNozzleExtinguishingFireEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.isExtinguishingFire = streamReadBool(streamId)

	self:run(connection)
end

function AttackNozzleExtinguishingFireEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.isExtinguishingFire)
end

function AttackNozzleExtinguishingFireEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setIsExtinguishingFire ~= nil then
		currentTool:setIsExtinguishingFire(self.isExtinguishingFire, false, true)
	end
end

function AttackNozzleExtinguishingFireEvent.sendEvent(player, isExtinguishingFire, noEventSend)
	local currentTool = player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setIsExtinguishingFire ~= nil and isExtinguishingFire ~= currentTool.isExtinguishingFire and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(AttackNozzleExtinguishingFireEvent.new(player, isExtinguishingFire), nil, nil, player)
		else
			g_client:getServerConnection():sendEvent(AttackNozzleExtinguishingFireEvent.new(player, isExtinguishingFire))
		end
	end
end
