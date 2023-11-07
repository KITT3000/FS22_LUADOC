EmergencyChainsaw = {}
local EmergencyChainsaw_mt = Class(EmergencyChainsaw, Chainsaw)

InitObjectClass(EmergencyChainsaw, "EmergencyChainsaw")

function EmergencyChainsaw.new(isServer, isClient, customMt)
	local self = EmergencyChainsaw:superClass().new(isServer, isClient, customMt or EmergencyChainsaw_mt)
	self.rolePlay = g_currentMission.rolePlay

	return self
end

function EmergencyChainsaw:postLoad(xmlFile)
	if not EmergencyChainsaw:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.rolePlay:addHandTool(self.configFileName)

	return true
end
