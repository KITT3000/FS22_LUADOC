StrawHarvestAnimationUtil = {}
local StrawHarvestAnimationUtil_mt = Class(StrawHarvestAnimationUtil, Object)

local function byNonGhost(first, second)
	return second.name < first.name and not first.isGhost and second.isGhost
end

function StrawHarvestAnimationUtil.registerAnimationPackageXMLPaths(schema, basePath, isGhost)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Animation package name", "defaultAnimationName")
	schema:register(XMLValueType.FLOAT, basePath .. "#speed", "Animation speed", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#loop", "Loop animation", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#duration", "Animation duration (s)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#callbackTime", "Callback time (s)", "duration")

	if not isGhost then
		AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
		StrawHarvestAnimationUtil.registerAnimationPackageSoundXMLPaths(schema, basePath .. ".sounds")
	end

	if isGhost then
		StrawHarvestAnimationUtil.registerAnimationPackageAnimationXMLPaths(schema, basePath)
	else
		StrawHarvestAnimationUtil.registerAnimationPackageAnimationXMLPaths(schema, basePath .. ".animation")
	end
end

function StrawHarvestAnimationUtil.registerAnimationPackageAnimationXMLPaths(schema, basePath)
	local animationPath = basePath .. ".part(?)"

	schema:register(XMLValueType.STRING, animationPath .. "#name", "Ghost animation name")
	schema:register(XMLValueType.NODE_INDEX, animationPath .. "#guideNode", "Guide node")
	schema:register(XMLValueType.NODE_INDEX, animationPath .. "#node", "Node")
	schema:register(XMLValueType.STRING, animationPath .. "#shaderParameter", "Shader parameter")
	schema:register(XMLValueType.VECTOR_4, animationPath .. "#shaderComponentScale", "Shader component scale", "0 0 0 0")
	AnimationManager.registerAnimationNodesXMLPaths(schema, animationPath .. ".animationNodes")
	StrawHarvestAnimationUtil.registerKeyFramesXMLPaths(schema, animationPath, {
		StrawHarvestAnimationUtil.registerKeyFrameAnimationXMLPaths,
		StrawHarvestAnimationUtil.registerKeyFrameShaderXMLPaths
	})
end

function StrawHarvestAnimationUtil.registerAnimationPackageSoundXMLPaths(schema, basePath)
	local soundPath = basePath .. ".sound(?)"

	SoundManager.registerSampleXMLPaths(schema, soundPath, "sample")
	StrawHarvestAnimationUtil.registerKeyFramesXMLPaths(schema, soundPath, {
		StrawHarvestAnimationUtil.registerKeyFrameSoundXMLPaths
	})
end

function StrawHarvestAnimationUtil.registerKeyFramesXMLPaths(schema, basePath, registerFunctions)
	local frameKey = basePath .. ".keyFrame(?)"

	schema:register(XMLValueType.FLOAT, frameKey .. "#keyTime", "Key frame", nil, true)

	for _, registerFunc in ipairs(registerFunctions) do
		registerFunc(schema, frameKey)
	end
end

function StrawHarvestAnimationUtil.registerKeyFrameAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#active", "Is active", true)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Key translation", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Key rotation", "0 0 0")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. "#scale", "Key scale", "1 1 1")
end

function StrawHarvestAnimationUtil.registerKeyFrameShaderXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_4, basePath .. "#value", "shaderParameter")
end

function StrawHarvestAnimationUtil.registerKeyFrameSoundXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#active", "Is active", false)
end

function StrawHarvestAnimationUtil.new(isServer, isClient, baseDirectory, customMt)
	local self = Object.new(isServer, isClient, customMt or StrawHarvestAnimationUtil_mt)
	self.animationPackages = {}
	self.ghostAnimations = {}
	self.baseDirectory = baseDirectory
	self.isActive = true

	return self
end

function StrawHarvestAnimationUtil:delete()
	for _, package in ipairs(self.animationPackages) do
		if package.sounds ~= nil then
			for _, sound in ipairs(package.sounds) do
				g_soundManager:deleteSample(sound.sample)
			end
		end

		g_animationManager:deleteAnimations(package.animationNodes)

		for _, part in ipairs(package.animation.parts) do
			if part.animationNodes ~= nil then
				g_animationManager:deleteAnimations(part.animationNodes)
			end
		end
	end

	self.animationPackages = {}

	StrawHarvestAnimationUtil:superClass().delete(self)
end

function StrawHarvestAnimationUtil:resetGhostPackages()
	local deletedNotes = self:deleteGhostPackages(true)
	self.callbacks = {}

	return deletedNotes
end

function StrawHarvestAnimationUtil:readStream(streamId, connection)
	StrawHarvestAnimationUtil:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		table.sort(self.animationPackages, byNonGhost)

		for _, package in ipairs(self.animationPackages) do
			local animationTime = streamReadFloat32(streamId)

			self:setAnimationPackageTime(package, animationTime)
		end
	end
end

function StrawHarvestAnimationUtil:writeStream(streamId, connection)
	StrawHarvestAnimationUtil:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		table.sort(self.animationPackages, byNonGhost)

		for _, package in ipairs(self.animationPackages) do
			streamWriteFloat32(streamId, package.animationTime)
		end
	end
end

function StrawHarvestAnimationUtil:readUpdateStream(streamId, timestamp, connection)
	StrawHarvestAnimationUtil:superClass().readUpdateStream(self, streamId, timestamp, connection)
end

function StrawHarvestAnimationUtil:writeUpdateStream(streamId, connection, dirtyMask)
	StrawHarvestAnimationUtil:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end

function StrawHarvestAnimationUtil:loadAnimationPackage(xmlFile, components, key, i3dMappings)
	local package = {
		name = xmlFile:getValue(key .. "#name", "defaultAnimationName"),
		currentRealTime = 0,
		animationTime = 0,
		isPlaying = false,
		isGhost = false,
		speed = xmlFile:getValue(key .. "#speed", 1),
		loop = xmlFile:getValue(key .. "#loop", false),
		duration = xmlFile:getValue(key .. "#duration", 1) * 1000,
		animation = self:loadAnimation(components, xmlFile, key .. ".animation", i3dMappings, package)
	}
	package.callbackTime = xmlFile:getValue(key .. "#callbackTime", package.duration * 0.001) * 1000
	package.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", components, self, i3dMappings)
	package.sounds = self:loadSounds(components, xmlFile, key .. ".sounds", i3dMappings, package)

	self:setAnimationPackageTime(package, package.animationTime)
	table.insert(self.animationPackages, package)
	table.sort(self.animationPackages, byNonGhost)

	return package
end

function StrawHarvestAnimationUtil:loadGhostAnimation(xmlFile, components, key, i3dMappings)
	local package = {
		currentRealTime = 0,
		animationTime = 0,
		isGhost = true,
		speed = xmlFile:getValue(key .. "#speed", 1),
		loop = xmlFile:getValue(key .. "#loop", false),
		duration = xmlFile:getValue(key .. "#duration", 1) * 1000,
		animation = self:loadAnimation(components, xmlFile, key, i3dMappings, package)
	}
	package.callbackTime = xmlFile:getValue(key .. "#callbackTime", package.duration * 0.001) * 1000

	table.insert(self.ghostAnimations, package)

	return package
end

function StrawHarvestAnimationUtil:loadAnimation(components, xmlFile, key, i3dMappings, package)
	local animation = {
		parts = {}
	}
	local i = 0

	while true do
		local partKey = ("%s.part(%d)"):format(key, i)

		if not xmlFile:hasProperty(partKey) then
			break
		end

		local part = {}

		if package.isGhost then
			part.name = xmlFile:getValue(partKey .. "#name")
			part.guideNode = xmlFile:getValue(partKey .. "#guideNode", nil, components, i3dMappings)
		else
			part.node = xmlFile:getValue(partKey .. "#node", nil, components, i3dMappings)
		end

		part.animCurve = AnimCurve.new(linearInterpolatorN)
		local shaderParameter = xmlFile:getValue(partKey .. "#shaderParameter")
		part.isShader = shaderParameter ~= nil
		local frameFunction = StrawHarvestAnimationUtil.loadAnimationFrame

		if part.isShader then
			part.shaderParameter = shaderParameter
			part.shaderComponentScale = xmlFile:getValue(partKey .. "#shaderComponentScale", "0 0 0 0", true)
			frameFunction = StrawHarvestAnimationUtil.loadAnimationShaderFrame
		end

		part.animationNodes = g_animationManager:loadAnimations(xmlFile, partKey .. ".animationNodes", components, self, i3dMappings)

		if StrawHarvestAnimationUtil.loadKeyFrames(xmlFile, partKey, part, package.duration, frameFunction) then
			table.insert(animation.parts, part)
		end

		i = i + 1
	end

	return animation
end

function StrawHarvestAnimationUtil.loadAnimationFrame(xmlFile, key)
	local x, y, z = xmlFile:getValue(key .. "#translation", "0 0 0")
	local rx, ry, rz = xmlFile:getValue(key .. "#rotation", "0 0 0")
	local sx, sy, sz = xmlFile:getValue(key .. "#scale", "1 1 1")
	local isActive = xmlFile:getValue(key .. "#active", true)
	local active = isActive and 1 or 0

	return {
		x,
		y,
		z,
		rx,
		ry,
		rz,
		sx,
		sy,
		sz,
		active
	}
end

function StrawHarvestAnimationUtil.loadSoundFrame(xmlFile, key)
	local isActive = xmlFile:getValue(key .. "#active", false)
	local active = isActive and 1 or 0

	return {
		active
	}
end

function StrawHarvestAnimationUtil.loadAnimationShaderFrame(xmlFile, key, part)
	local xScale, yScale, zScale, wScale = unpack(part.shaderComponentScale)
	local x, y, z, w = xmlFile:getValue(key .. "#value")

	return {
		x * xScale,
		y * yScale,
		z * zScale,
		w * wScale
	}
end

function StrawHarvestAnimationUtil.loadKeyFrames(xmlFile, key, part, duration, loadFrameValuesFunc)
	local i = 0

	while true do
		local frameKey = ("%s.keyFrame(%d)"):format(key, i)

		if not xmlFile:hasProperty(frameKey) then
			break
		end

		local keyTime = xmlFile:getValue(frameKey .. "#keyTime")

		if keyTime == nil then
			break
		end

		local keyFrame = loadFrameValuesFunc(xmlFile, frameKey, part)
		keyFrame.time = MathUtil.clamp(keyTime * 1000 / duration, 0, 1)

		part.animCurve:addKeyframe(keyFrame)

		i = i + 1
	end

	return i > 0
end

function StrawHarvestAnimationUtil:loadSounds(baseNode, xmlFile, key, i3dMappings, package)
	local sounds = {}
	local i = 0

	while true do
		local soundKey = ("%s.sound(%d)"):format(key, i)

		if not xmlFile:hasProperty(soundKey) then
			break
		end

		local sound = {
			sample = g_soundManager:loadSampleFromXML(xmlFile, soundKey, "sample", self.baseDirectory, baseNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil),
			animCurve = AnimCurve.new(linearInterpolatorN)
		}

		if StrawHarvestAnimationUtil.loadKeyFrames(xmlFile, soundKey, sound, package.duration, StrawHarvestAnimationUtil.loadSoundFrame) then
			table.insert(sounds, sound)
		end

		i = i + 1
	end

	return sounds
end

function StrawHarvestAnimationUtil:createGhostPackage(package, nodes, removeCallback, removeCallbackTarget)
	local instance = {
		name = "ghost",
		animationTime = 0,
		currentRealTime = 0,
		isPlaying = false,
		isGhost = true,
		duration = package.duration,
		loop = package.loop,
		animation = package.animation,
		speed = package.speed,
		callbackTime = package.callbackTime,
		nodes = nodes,
		removeCallback = removeCallback,
		removeCallbackTarget = removeCallbackTarget
	}

	if instance.animation ~= nil then
		for _, part in ipairs(instance.animation.parts) do
			local nodeToLink = nodes[part.name]

			if nodeToLink ~= nil then
				link(part.guideNode, nodeToLink)
			end
		end
	end

	table.insert(self.animationPackages, instance)
	table.sort(self.animationPackages, byNonGhost)

	return instance
end

function StrawHarvestAnimationUtil:deleteGhostPackage(ghostPackage, deleteNodes)
	local numOfDeletedNodes = 0
	self.packagesToRemove = {}

	for i = #self.animationPackages, 1, -1 do
		local package = self.animationPackages[i]

		if package.isGhost and ghostPackage == package then
			package.isPlaying = false

			if deleteNodes then
				for _, _ in pairs(ghostPackage.nodes) do
					numOfDeletedNodes = numOfDeletedNodes + 1
				end
			end

			table.insert(self.packagesToRemove, {
				index = i,
				deleteNodes = deleteNodes
			})

			break
		end
	end

	return numOfDeletedNodes
end

function StrawHarvestAnimationUtil:deleteGhostPackages(deleteNodes)
	local numOfDeletedNodes = 0
	self.packagesToRemove = {}

	for i = #self.animationPackages, 1, -1 do
		local package = self.animationPackages[i]

		if package.isGhost then
			package.isPlaying = false

			if deleteNodes then
				for _, _ in pairs(package.nodes) do
					numOfDeletedNodes = numOfDeletedNodes + 1
				end
			end

			table.insert(self.packagesToRemove, {
				index = i,
				deleteNodes = deleteNodes
			})
		end
	end

	return numOfDeletedNodes
end

function StrawHarvestAnimationUtil:setAnimationPackageSpeed(package, speed)
	package.speed = speed
end

function StrawHarvestAnimationUtil:getAnimationPackageSpeed(package)
	return package.speed
end

function StrawHarvestAnimationUtil:playAnimationPackage(package, startTime, callbackFunction, callbackTarget, callbackParams)
	package.isPlaying = true

	self:setAnimationPackageTime(package, Utils.getNoNil(startTime, package.currentRealTime))

	package.callbackFunction = callbackFunction
	package.callbackTarget = callbackTarget
	package.callbackParams = callbackParams or {}
	package.callbackOnce = false
	package.speed = 1

	g_animationManager:startAnimations(package.animationNodes)
	self:raiseActive()
end

function StrawHarvestAnimationUtil:playAnimationPackageUntil(package, startTime, stopTime, callbackFunction, callbackTarget, callbackParams)
	package.isPlaying = true
	startTime = Utils.getNoNil(startTime, package.currentRealTime)
	local direction = stopTime < startTime and -1 or 1
	package.speed = math.abs(package.speed) * direction

	self:setAnimationPackageTime(package, startTime / package.duration)

	package.callbackTime = stopTime
	package.callbackFunction = callbackFunction
	package.callbackTarget = callbackTarget
	package.callbackParams = callbackParams or {}
	package.callbackOnce = true

	g_animationManager:startAnimations(package.animationNodes)
	self:raiseActive()
end

function StrawHarvestAnimationUtil:stopAnimationPackage(package)
	package.isPlaying = false

	if package.callbackOnce then
		self:clearCallbackOnPackage(package)
	end

	g_animationManager:stopAnimations(package.animationNodes)

	for _, part in ipairs(package.animation.parts) do
		if part.animationNodes ~= nil then
			g_animationManager:stopAnimations(part.animationNodes)
		end
	end

	self:raiseActive()
end

function StrawHarvestAnimationUtil:getAnimationPackageTime(package)
	return package.currentRealTime / package.duration
end

function StrawHarvestAnimationUtil:setAnimationPackageTime(package, animationTime)
	animationTime = MathUtil.clamp(animationTime, 0, 1)
	package.animationTime = animationTime
	package.currentRealTime = package.duration * animationTime

	for _, part in ipairs(package.animation.parts) do
		local node = part.node

		if package.isGhost then
			node = package.nodes[part.name]
		end

		local values = part.animCurve:get(animationTime)

		if part.isShader then
			self:setAnimationShaderFrameValues(node, part, values)
		else
			self:setAnimationFrameValues(node, part, values)
		end
	end

	return animationTime
end

function StrawHarvestAnimationUtil:setAnimationFrameValues(node, part, v)
	local isActive = v[10] == 1

	if node ~= nil then
		setTranslation(node, v[1], v[2], v[3])
		setRotation(node, v[4], v[5], v[6])
		setScale(node, v[7], v[8], v[9])
		setVisibility(node, isActive)
	end

	if isActive then
		g_animationManager:startAnimations(part.animationNodes)
	else
		g_animationManager:stopAnimations(part.animationNodes)
	end
end

function StrawHarvestAnimationUtil:setAnimationShaderFrameValues(node, part, v)
	local x, y, z, w = unpack(v)

	setShaderParameter(node, part.shaderParameter, x, y, z, w, false)
end

function StrawHarvestAnimationUtil:getRealAnimationPackageTime(package)
	return package.currentRealTime
end

function StrawHarvestAnimationUtil:setRealAnimationPackageTime(package, realAnimationTime)
	self:setAnimationPackageTime(package, realAnimationTime / package.duration)
end

function StrawHarvestAnimationUtil:isAnimationPackagePlaying(package)
	return package.isPlaying
end

function StrawHarvestAnimationUtil:setIsAnimationPackagePlaying(package, isPlaying)
	if isPlaying then
		self:playAnimationPackage(package)
	else
		self:stopAnimationPackage(package)
	end
end

function StrawHarvestAnimationUtil:getAnimationPackageDuration(package)
	return package.duration
end

function StrawHarvestAnimationUtil.canAddCallback(time, newTime, callbackTime)
	return time <= callbackTime and callbackTime <= newTime or callbackTime <= time and newTime <= callbackTime
end

function StrawHarvestAnimationUtil:addCallback(callbacks, package)
	if package.callbackFunction ~= nil and package.callbackTarget ~= nil then
		table.insert(callbacks, {
			func = package.callbackFunction,
			target = package.callbackTarget,
			params = package.callbackParams
		})
	end
end

function StrawHarvestAnimationUtil:clearCallbackOnPackage(package)
	package.callbackFunction = nil
	package.callbackTarget = nil
	package.callbackParams = {}
end

function StrawHarvestAnimationUtil:setIsActive(isActive)
	self.isActive = isActive
end

function StrawHarvestAnimationUtil:update(dt)
	StrawHarvestAnimationUtil:superClass().update(self, dt)

	if self.packagesToRemove ~= nil then
		for _, desc in ipairs(self.packagesToRemove) do
			local package = self.animationPackages[desc.index]

			if desc.deleteNodes then
				for _, node in pairs(package.nodes) do
					if package.removeCallback ~= nil then
						package.removeCallback(package.removeCallbackTarget, node)
					else
						delete(node)
					end
				end
			end

			table.remove(self.animationPackages, desc.index)
		end

		self.packagesToRemove = nil
	end

	if not self.isActive then
		return
	end

	self.callbacks = {}

	for _, package in ipairs(self.animationPackages) do
		if package.isPlaying then
			local lastRealAnimationTime = package.currentRealTime
			local newAnimationTime = math.min(package.currentRealTime + dt * package.speed, package.duration)
			local animationTime = MathUtil.clamp(newAnimationTime / package.duration, 0, 1)

			self:setAnimationPackageTime(package, animationTime)

			if StrawHarvestAnimationUtil.canAddCallback(lastRealAnimationTime, package.currentRealTime, package.callbackTime) then
				self:addCallback(self.callbacks, package)

				if package.callbackOnce then
					self:stopAnimationPackage(package)
				end
			end

			if package.sounds ~= nil then
				for _, sound in ipairs(package.sounds) do
					local isActiveValue = unpack(sound.animCurve:get(MathUtil.clamp(package.currentRealTime / package.duration, 0, 1)))
					local playSample = isActiveValue > 0

					if playSample then
						if not g_soundManager:getIsSamplePlaying(sound.sample) then
							g_soundManager:playSample(sound.sample)
						end
					elseif g_soundManager:getIsSamplePlaying(sound.sample) then
						g_soundManager:stopSample(sound.sample)
					end
				end
			end

			if package.speed > 0 and package.currentRealTime == package.duration or package.speed < 0 and package.currentRealTime == 0 then
				if package.loop then
					local realTime = package.speed > 0 and 0 or package.duration

					self:setRealAnimationPackageTime(package, realTime)
				else
					self:stopAnimationPackage(package)
				end
			end

			self:raiseActive()
		end
	end

	for _, callback in ipairs(self.callbacks) do
		callback.func(callback.target, unpack(callback.params))
	end
end
