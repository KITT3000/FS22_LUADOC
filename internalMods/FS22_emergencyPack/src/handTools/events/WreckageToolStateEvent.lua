WreckageToolStateEvent = {}
local WreckageToolStateEvent_mt = Class(WreckageToolStateEvent, Event)

InitEventClass(WreckageToolStateEvent, "WreckageToolStateEvent")

function WreckageToolStateEvent.emptyNew()
	return Event.new(WreckageToolStateEvent_mt)
end

function WreckageToolStateEvent.new(player, isInWorkRange, isInFocusRange)
	local self = WreckageToolStateEvent.emptyNew()
	self.player = player
	self.isInWorkRange = isInWorkRange
	self.isInFocusRange = isInFocusRange

	return self
end

function WreckageToolStateEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.isInWorkRange = streamReadBool(streamId)
	self.isInFocusRange = streamReadBool(streamId)

	self:run(connection)
end

function WreckageToolStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.isInWorkRange)
	streamWriteBool(streamId, self.isInFocusRange)
end

function WreckageToolStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool

	if currentTool ~= nil then
		currentTool.isInWorkRange = self.isInWorkRange
		currentTool.isInFocusRange = self.isInFocusRange
	end
end

function WreckageToolStateEvent.sendEvent(player, isInWorkRange, isInFocusRange, noEventSend)
	local currentTool = player.baseInformation.currentHandtool

	if currentTool ~= nil and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(WreckageToolStateEvent.new(player, isInWorkRange, isInFocusRange), nil, nil, player)
		else
			g_client:getServerConnection():sendEvent(WreckageToolStateEvent.new(player, isInWorkRange, isInFocusRange))
		end
	end
end
