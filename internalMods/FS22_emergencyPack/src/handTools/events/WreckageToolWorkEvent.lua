WreckageToolWorkEvent = {}
local WreckageToolWorkEvent_mt = Class(WreckageToolWorkEvent, Event)

InitEventClass(WreckageToolWorkEvent, "WreckageToolWorkEvent")

function WreckageToolWorkEvent.emptyNew()
	local self = Event.new(WreckageToolWorkEvent_mt)

	return self
end

function WreckageToolWorkEvent.new(player, isWorking)
	local self = WreckageToolWorkEvent.emptyNew()
	self.player = player
	self.isWorking = isWorking

	return self
end

function WreckageToolWorkEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.isWorking = streamReadBool(streamId)

	self:run(connection)
end

function WreckageToolWorkEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.isWorking)
end

function WreckageToolWorkEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setIsWorking ~= nil then
		currentTool:setIsWorking(self.isWorking, false, true)
	end
end

function WreckageToolWorkEvent.sendEvent(player, isWorking, noEventSend)
	local currentTool = player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setIsWorking ~= nil and isWorking ~= currentTool.isWorking and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(WreckageToolWorkEvent.new(player, isWorking), nil, nil, player)
		else
			g_client:getServerConnection():sendEvent(WreckageToolWorkEvent.new(player, isWorking))
		end
	end
end
