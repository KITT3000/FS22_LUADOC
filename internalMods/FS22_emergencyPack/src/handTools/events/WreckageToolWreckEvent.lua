WreckageToolWreckEvent = {}
local WreckageToolWreckEvent_mt = Class(WreckageToolWreckEvent, Event)

InitEventClass(WreckageToolWreckEvent, "WreckageToolWreckEvent")

function WreckageToolWreckEvent.emptyNew()
	local self = Event.new(WreckageToolWreckEvent_mt)

	return self
end

function WreckageToolWreckEvent.new(player)
	local self = WreckageToolWreckEvent.emptyNew()
	self.player = player

	return self
end

function WreckageToolWreckEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function WreckageToolWreckEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
end

function WreckageToolWreckEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.wreckObject ~= nil then
		currentTool:wreckObject(true)
	end
end

function WreckageToolWreckEvent.sendEvent(player, noEventSend)
	local currentTool = player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.wreckObject ~= nil and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(WreckageToolWreckEvent.new(player), nil, nil, player)
		else
			g_client:getServerConnection():sendEvent(WreckageToolWreckEvent.new(player))
		end
	end
end
