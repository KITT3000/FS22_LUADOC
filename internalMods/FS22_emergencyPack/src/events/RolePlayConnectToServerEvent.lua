RolePlayConnectToServerEvent = {}
local RolePlayConnectToServerEvent_mt = Class(RolePlayConnectToServerEvent, Event)

InitEventClass(RolePlayConnectToServerEvent, "RolePlayConnectToServerEvent")

function RolePlayConnectToServerEvent.emptyNew()
	local self = Event.new(RolePlayConnectToServerEvent_mt)

	return self
end

function RolePlayConnectToServerEvent.new()
	local self = RolePlayConnectToServerEvent.emptyNew()

	return self
end

function RolePlayConnectToServerEvent:writeStream(streamId, connection)
	g_currentMission.rolePlay:writeStream(streamId, connection)
end

function RolePlayConnectToServerEvent:readStream(streamId, connection)
	g_currentMission.rolePlay:readStream(streamId, connection)
	self:run(connection)
end

function RolePlayConnectToServerEvent:run(connection)
end
