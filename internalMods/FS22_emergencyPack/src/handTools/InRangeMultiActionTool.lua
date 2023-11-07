InRangeMultiActionTool = {
	INTERACTION_DELAY = 2000,
	EFFECT_DELAY = 3000
}
local InRangeMultiActionTool_mt = Class(InRangeMultiActionTool, RolePlayHandTool)

InitObjectClass(InRangeMultiActionTool, "InRangeMultiActionTool")

function InRangeMultiActionTool.registerXMLPaths(schema, basePath)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".inRangeMultiActionTool.sounds", "work")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".inRangeMultiActionTool.effects")
	schema:register(XMLValueType.STRING, basePath .. ".inRangeMultiActionTool.workingAnimation#name", "Working animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".inRangeMultiActionTool.workingAnimation#workingDirection", "Working animation direction if is working", 1)
	schema:register(XMLValueType.INT, basePath .. ".inRangeMultiActionTool#inRangeDistance", "The in range distance")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".inRangeMultiActionTool#interactText", "The interaction text")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".inRangeMultiActionTool#actionText", "The action text")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".inRangeMultiActionTool#objectReferenceId", "The object reference id to lookup")
	schema:register(XMLValueType.STRING, basePath .. ".inRangeMultiActionTool.marker#file", "The marker i3d file")
end

function InRangeMultiActionTool.new(isServer, isClient, customMt)
	local self = InRangeMultiActionTool:superClass().new(isServer, isClient, customMt or InRangeMultiActionTool_mt)
	self.interactionDelay = PlacementTool.INTERACTION_DELAY
	self.isInRange = false
	self.inRangeDistance = 3
	self.effectDirty = false
	self.effectTimer = InRangeMultiActionTool.EFFECT_DELAY

	return self
end

function InRangeMultiActionTool:postLoad(xmlFile)
	if not InRangeMultiActionTool:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.inRangeDistance = xmlFile:getValue("handTool.inRangeMultiActionTool#inRangeDistance", self.inRangeDistance)
	self.playerInputText = xmlFile:getValue("handTool.inRangeMultiActionTool#interactText", "input_rescueInObject", self.customEnvironment)
	self.playerInputActionText = xmlFile:getValue("handTool.inRangeMultiActionTool#actionText", "input_rescue", self.customEnvironment)
	self.effects = g_effectManager:loadEffect(xmlFile, "handTool.inRangeMultiActionTool.effects", self.components, self, self.i3dMappings)
	self.sample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.inRangeMultiActionTool.sounds", "work", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	local animation = {
		name = xmlFile:getValue("handTool.inRangeMultiActionTool.workingAnimation#name"),
		workingDirection = xmlFile:getValue("handTool.inRangeMultiActionTool.workingAnimation#workingDirection", 1)
	}
	self.workingAnimation = animation

	if self.isClient then
		local filename = xmlFile:getValue("handTool.inRangeMultiActionTool.marker#file")

		if filename ~= nil then
			filename = Utils.getFilename(filename, self.baseDirectory)

			g_i3DManager:pinSharedI3DFileInCache(filename)

			self.sharedLoadRequestIdMarker = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.onMarkerLoaded, self, self.player)
		end
	end

	return true
end

function InRangeMultiActionTool:onMarkerLoaded(node, failedReason, args)
	if node ~= 0 then
		if not self.isDeleted then
			self.marker = getChildAt(node, 0)

			setVisibility(self.marker, false)
			setScale(self.marker, 1, 0.5, 0.5)
			link(self.handNode, self.marker)
		end

		delete(node)
	end
end

function InRangeMultiActionTool:delete()
	if self.isClient then
		if self.marker ~= nil then
			delete(self.marker)

			self.marker = nil
		end

		if self.sharedLoadRequestIdMarker ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestIdMarker)

			self.sharedLoadRequestIdMarker = nil
		end
	end

	g_effectManager:deleteEffects(self.effects)
	g_soundManager:deleteSample(self.sample)
	InRangeMultiActionTool:superClass().delete(self)
end

function InRangeMultiActionTool:onActivate(allowInput)
	InRangeMultiActionTool:superClass().onActivate(self, allowInput)

	self.interactionDelay = InRangeMultiActionTool.INTERACTION_DELAY
end

function InRangeMultiActionTool:onDeactivate(allowInput)
	self:doAction(false)

	self.isInRange = false

	InRangeMultiActionTool:superClass().onDeactivate(self, allowInput)
end

function InRangeMultiActionTool:update(dt, allowInput)
	InRangeMultiActionTool:superClass().update(self, dt, allowInput)

	if self.isClient then
		if self.isInRange and self.interactionDelay <= 0 then
			self:setPlayerInputText(self.playerInputActionText)
			self:updateVisual(false)
		else
			self:updateVisual(true)
			self:resetPlayerInputText()
		end

		if self.effectTimer > 0 then
			self.effectTimer = self.effectTimer - dt
		else
			self.effectDirty = false
		end

		if self.effectDirty then
			g_effectManager:startEffects(self.effects)
		else
			g_effectManager:stopEffects(self.effects)
		end

		self:updateMarker()
	end

	if self.isActive and allowInput and self.activatePressed and self.isInRange and self.interactionDelay <= 0 then
		self.interactionDelay = InRangeMultiActionTool.INTERACTION_DELAY

		self:doAction(true)
	end

	self.interactionDelay = self.interactionDelay - dt
	self.activatePressed = false
end

function InRangeMultiActionTool:updateTick(dt, allowInput)
	InRangeMultiActionTool:superClass().updateTick(self, dt, allowInput)

	self.isInRange, self.inRangeRef = self:isReferenceInRange()

	if not self.isServer then
		return
	end

	if self.setAction then
		return
	end

	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return
	end

	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil or not checkpoint.isActive then
		return
	end

	if self.isActive and self.state then
		checkpoint:setActionCompleted(true)

		self.setAction = true
	end
end

function InRangeMultiActionTool:updateMarker()
	if self.marker ~= nil then
		if self.inRangeRef ~= nil and self.player == g_currentMission.player then
			local x, y, z = localToWorld(self.inRangeRef.node, 0, 1, 0)

			setWorldTranslation(self.marker, x, y, z)

			local dirX, dirY, dirZ = localDirectionToWorld(getRootNode(), 0, 1, 0)
			dirX, dirY, dirZ = worldDirectionToLocal(getParent(self.marker), dirX, dirY, dirZ)

			I3DUtil.setDirection(self.marker, dirX, dirY, dirZ, 0, 1, 0)
			setVisibility(self.marker, true)
		else
			setVisibility(self.marker, false)
		end
	end
end

function InRangeMultiActionTool:isReferenceInRange()
	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return false
	end

	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil or not checkpoint.isActive then
		return false
	end

	local references = checkpoint:getObjectReferences()
	local closestDistance = math.huge
	local closestReference, inRangeReference = nil
	local isInRange = false

	if references ~= nil then
		for _, reference in pairs(references) do
			local object = reference.object

			if object:isa(OilSpot) and not object:isThreaten() then
				local distance = calcDistanceFrom(reference.node, self.handNode)

				if distance < closestDistance then
					closestDistance = distance
					closestReference = reference
					isInRange = distance < self.inRangeDistance

					if isInRange then
						inRangeReference = reference
					end
				end
			end
		end
	end

	return isInRange, inRangeReference
end

function InRangeMultiActionTool:doAction(state)
	self:setState(state)
end

function InRangeMultiActionTool:setState(state, noEventSend)
	RolePlayHandToolStateEvent.sendEvent(self.player, state, noEventSend)

	if self.isClient then
		g_soundManager:stopSample(self.sample)
	end

	self.effectDirty = true
	self.effectTimer = InRangeMultiActionTool.EFFECT_DELAY
	local ref = self.inRangeRef

	if state and ref ~= nil then
		ref.object:setIsThreaten(true)

		if self.isClient then
			g_soundManager:playSample(self.sample)
		end

		local animation = self.workingAnimation

		if animation.name ~= nil then
			self.animations:setAnimationTime(animation.name, 0)
			self.animations:playAnimation(animation.name, animation.workingDirection)
		end

		if self.marker ~= nil then
			setVisibility(self.marker, false)
		end
	end

	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return
	end

	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil or not checkpoint.isActive then
		return
	end

	local references = checkpoint:getObjectReferences()

	for _, reference in pairs(references) do
		local object = reference.object

		if object:isa(OilSpot) and not object:isThreaten() then
			return
		end
	end

	if self.state ~= state then
		self.state = state
	end
end
