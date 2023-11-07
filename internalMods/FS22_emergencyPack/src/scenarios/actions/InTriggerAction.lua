InTriggerAction = {}
local InTriggerAction_mt = Class(InTriggerAction, ScenarioAction)

function InTriggerAction.registerXMLPaths(schema, basePath)
end

function InTriggerAction.new(checkpoint)
	local self = InTriggerAction:superClass().new(checkpoint, InTriggerAction_mt)
	self.hasEntered = false
	self.hasLeft = false

	return self
end

function InTriggerAction:delete()
	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)
	end

	self.triggerObject:delete()
	InTriggerAction:superClass().delete(self)
end

function InTriggerAction:onUpdate(dt)
	InTriggerAction:superClass().onUpdate(self, dt)

	if (self.hasEntered or self.hasLeft) and not self:isCompleted() then
		self.checkpoint:setActionCompleted(true)
	end
end

function InTriggerAction:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode)
	if not InTriggerAction:superClass().loadFromXML(self, xmlFile, baseKey, baseDirectory, rootNode) then
		return false
	end

	self.triggerObject = ScenarioObject.new()

	if self.triggerObject:loadFromXML(xmlFile, baseKey .. ".trigger", baseDirectory, rootNode) then
		self.triggerNode = self.triggerObject.nodeId

		addTrigger(self.triggerNode, "triggerCallback", self)
	end

	return true
end

function InTriggerAction:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local farmId = self.checkpoint:getFarmId()
	local vehicle = g_currentMission.nodeToObject[otherId]

	if vehicle ~= nil then
		if vehicle:getOwnerFarmId() ~= farmId then
			return
		end

		if vehicle.spec_splineVehicle ~= nil or vehicle.spec_rolePlayVehicle == nil or not vehicle:getIsControlled() then
			return
		end
	end

	if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode and g_currentMission.player.farmId ~= farmId then
		return
	end

	if self.checkpoint.isActive then
		if onEnter then
			self.hasEntered = true
		end

		if self.hasEntered and onLeave then
			self.hasLeft = true
		end
	end
end

function InTriggerAction:onStart()
	InTriggerAction:superClass().onStart(self)

	local x = 0
	local y = 0
	local z = 0

	if self.objectReferenceId ~= nil then
		local ref = self.checkpoint:getObjectReferenceById(self.objectReferenceId)
		x, y, z = getWorldTranslation(ref.node)
	else
		x, y, z = getWorldTranslation(self.rootNode)
	end

	self.triggerObject:setWorldPosition(x, y, z, true)
end

function InTriggerAction:canBeCompleted()
	return self.checkpoint.isActive
end
