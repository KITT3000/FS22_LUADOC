RolePlayHandTool = {}
local RolePlayHandTool_mt = Class(RolePlayHandTool, HandTool)

InitObjectClass(RolePlayHandTool, "RolePlayHandTool")
g_xmlManager:addInitSchemaFunction(function ()
	local schema = HandTool.xmlSchema

	schema:setXMLSpecializationType("RolePlayHandTool")
	InRangeActionTool.registerXMLPaths(schema, "handTool")
	PlacementTool.registerXMLPaths(schema, "handTool")
	AttackNozzle.registerXMLPaths(schema, "handTool")
	WreckageTool.registerXMLPaths(schema, "handTool")
	AnimatedHandTool.registerXMLPaths(schema, "handTool")
	InRangeMultiActionTool.registerXMLPaths(schema, "handTool")
	schema:setXMLSpecializationType()
end)

function RolePlayHandTool.new(isServer, isClient, customMt)
	local self = RolePlayHandTool:superClass().new(isServer, isClient, customMt or RolePlayHandTool_mt)
	self.rolePlay = g_currentMission.rolePlay
	self.playerInputText = nil
	self.state = false
	self.animations = AnimatedHandTool.new(isServer, isClient)

	return self
end

function RolePlayHandTool:postLoad(xmlFile)
	if not RolePlayHandTool:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.rolePlay:addHandTool(self.configFileName)
	self.animations:loadFromXMLFile(xmlFile, "handTool", self.components, self.i3dMappings)

	return true
end

function RolePlayHandTool:update(dt, allowInput)
	RolePlayHandTool:superClass().update(self, dt, allowInput)
	self.animations:update(dt)
end

function RolePlayHandTool:onActivate(allowInput)
	RolePlayHandTool:superClass().onActivate(self, allowInput)

	self.originalPlayerInputText = nil

	self:setPlayerInputText(self.playerInputText)
end

function RolePlayHandTool:onDeactivate(allowInput)
	RolePlayHandTool:superClass().onDeactivate(self, allowInput)

	if self.playerInputText ~= nil then
		self:setPlayerInputText(self.originalPlayerInputText)
	end
end

function RolePlayHandTool:resetPlayerInputText()
	if self.playerInputText ~= nil then
		self:setPlayerInputText(self.playerInputText)
	else
		self:setPlayerInputText(self.originalPlayerInputText)
	end
end

function RolePlayHandTool:setPlayerInputText(text)
	local info = self.player.inputInformation.registrationList[InputAction.ACTIVATE_HANDTOOL]

	if self.originalPlayerInputText == nil then
		self.originalPlayerInputText = info.text
	end

	if text ~= nil then
		g_inputBinding:setActionEventText(info.eventId, text)
	end
end

function RolePlayHandTool:setState(state, noEventSend)
	RolePlayHandToolStateEvent.sendEvent(self.player, state, noEventSend)

	if self.state ~= state then
		self.state = state
	end
end

function RolePlayHandTool:updateVisual(doReset)
end
