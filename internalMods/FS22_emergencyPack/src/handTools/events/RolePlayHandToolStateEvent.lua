RolePlayHandToolStateEvent = {}
local RolePlayHandToolStateEvent_mt = Class(RolePlayHandToolStateEvent, Event)

InitEventClass(RolePlayHandToolStateEvent, "RolePlayHandToolStateEvent")

function RolePlayHandToolStateEvent.emptyNew()
	return Event.new(RolePlayHandToolStateEvent_mt)
end

function RolePlayHandToolStateEvent.new(player, state)
	local self = RolePlayHandToolStateEvent.emptyNew()
	self.player = player
	self.state = state

	return self
end

function RolePlayHandToolStateEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function RolePlayHandToolStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.state)
end

function RolePlayHandToolStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setState ~= nil then
		currentTool:setState(self.state, true)
	end
end

function RolePlayHandToolStateEvent.sendEvent(player, state, noEventSend)
	local currentTool = player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setState ~= nil and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(RolePlayHandToolStateEvent.new(player, state), nil, nil, player)
		else
			g_client:getServerConnection():sendEvent(RolePlayHandToolStateEvent.new(player, state))
		end
	end
end
