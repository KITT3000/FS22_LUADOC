FromVehicleAction = {}
local FromVehicleAction_mt = Class(FromVehicleAction, ScenarioAction)

function FromVehicleAction.registerXMLPaths(schema, basePath)
end

function FromVehicleAction.new(checkpoint)
	local self = FromVehicleAction:superClass().new(checkpoint, FromVehicleAction_mt)

	return self
end

function FromVehicleAction:delete()
	InTriggerAction:superClass().delete(self)
end

function FromVehicleAction:onUpdate(dt)
	FromVehicleAction:superClass().onUpdate(self, dt)

	if not self.checkpoint.isActive then
		return
	end

	if self.setAction then
		return
	end

	local farmId = self.checkpoint:getFarmId()
	local player = g_currentMission.player

	if player == nil or player.farmId ~= farmId then
		return
	end

	local closestVehicle, closestDistance = g_currentMission.rolePlay:getClosestVehicle(player.rootNode, farmId)

	if closestVehicle ~= nil and closestDistance < self.inRangeDistance then
		if self.requiredCategory == nil then
			if not self:isCompleted() then
				self.setAction = true

				self.checkpoint:setActionCompleted(true)
			end
		elseif closestVehicle:hasRolePlayCategories() then
			if table.hasElement(closestVehicle:getRolePlayCategories(), self.requiredCategory) then
				if not self:isCompleted() then
					self.setAction = true

					self.checkpoint:setActionCompleted(true)
				end
			else
				g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_vehicleDoesNotHaveRequiredToolCategory"), self.requiredCategory), 100)
			end
		end
	end
end

function FromVehicleAction:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode)
	if not FromVehicleAction:superClass().loadFromXML(self, xmlFile, baseKey, baseDirectory, rootNode) then
		return false
	end

	self.setAction = false
	self.inRangeDistance = xmlFile:getInt(baseKey .. "#inRangeDistance", 3)
	self.requiredCategory = xmlFile:getString(baseKey .. "#requiredCategory")

	return true
end

function FromVehicleAction:onStart()
	FromVehicleAction:superClass().onStart(self)
end

function FromVehicleAction:canBeCompleted()
	return self.checkpoint.isActive
end
