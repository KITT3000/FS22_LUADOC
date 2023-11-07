AnimatedHandTool = {}
local animatedHandTool_mt = Class(AnimatedHandTool)

InitObjectClass(AnimatedHandTool, "AnimatedHandTool")

function AnimatedHandTool.registerXMLPaths(schema, basePath)
	local animationKey = basePath .. ".animations.animation(?)"

	schema:register(XMLValueType.STRING, animationKey .. "#name", "Animation name", nil, true)
	schema:register(XMLValueType.FLOAT, animationKey .. "#duration", "Animation duration (sec.)", 3)
	schema:register(XMLValueType.NODE_INDEX, animationKey .. ".part(?)#node", "Part node")
	schema:register(XMLValueType.FLOAT, animationKey .. ".part(?).keyFrame(?)#time", "Key time")
	schema:register(XMLValueType.VECTOR_ROT, animationKey .. ".part(?).keyFrame(?)#rotation", "Key rotation", "values read from i3d node")
	schema:register(XMLValueType.VECTOR_TRANS, animationKey .. ".part(?).keyFrame(?)#translation", "Key translation", "values read from i3d node")
	schema:register(XMLValueType.VECTOR_SCALE, animationKey .. ".part(?).keyFrame(?)#scale", "Key scale", "values read from i3d node")
	schema:register(XMLValueType.BOOL, animationKey .. ".part(?).keyFrame(?)#visibility", "Key visibility", true)
	schema:register(XMLValueType.NODE_INDEX, animationKey .. ".shader(?)#node", "Shader node")
	schema:register(XMLValueType.STRING, animationKey .. ".shader(?)#parameterName", "Shader parameter name")
	schema:register(XMLValueType.FLOAT, animationKey .. ".shader(?).keyFrame(?)#time", "Key time")
	schema:register(XMLValueType.STRING, animationKey .. ".shader(?).keyFrame(?)#values", "Key shader parameter values. Use '-' to force using existing shader parameter value")
	schema:register(XMLValueType.NODE_INDEX, animationKey .. ".clip#rootNode", "I3d animation rootnode")
	schema:register(XMLValueType.STRING, animationKey .. ".clip#name", "I3d animation clipName")
	schema:register(XMLValueType.STRING, animationKey .. ".clip#filename", "I3d animation external animation")
	schema:register(XMLValueType.FLOAT, animationKey .. "#initialTime", "Animation time after loading", 0)
end

function AnimatedHandTool.new(isServer, isClient, customMt)
	local self = setmetatable({}, customMt or animatedHandTool_mt)
	self.animations = {}
	self.animationsByName = {}

	return self
end

function AnimatedHandTool:loadFromXMLFile(xmlFile, key, components, i3dMappings)
	local baseKey = key .. ".animations"

	xmlFile:iterate(baseKey .. ".animation", function (_, animationKey)
		local animation = {}

		if self:loadAnimationFromXMLFile(xmlFile, animationKey, animation, components, i3dMappings) then
			table.addElement(self.animations, animation)

			self.animationsByName[animation.name] = animation

			self:setAnimationTime(animation.name, animation.initialTime / animation.duration)
		else
			Logging.xmlWarning(xmlFile, "Could not handtool animation for '%s'", animationKey)

			return false
		end
	end)
end

function AnimatedHandTool:loadAnimationFromXMLFile(xmlFile, key, animation, components, i3dMappings)
	animation.name = xmlFile:getValue(key .. "#name")
	animation.duration = xmlFile:getValue(key .. "#duration") * 1000
	animation.initialTime = xmlFile:getValue(key .. "#initialTime", 0) * 1000

	if self.animationsByName[name] ~= nil then
		return false
	end

	animation.parts = {}

	xmlFile:iterate(key .. ".part", function (_, partKey)
		local part = {}

		if self:loadAnimationPartFromXMLFile(xmlFile, partKey, part, components, i3dMappings) then
			table.addElement(animation.parts, part)
		else
			Logging.xmlWarning(xmlFile, "Could not handtool animation part for '%s'", partKey)

			return false
		end
	end)

	for _, part in ipairs(animation.parts) do
		part.animCurve = AnimCurve.new(linearInterpolatorN)

		for _, frame in ipairs(part.frames) do
			if animation.duration == nil then
				frame.time = frame.time / animation.maxTime
			end

			part.animCurve:addKeyframe(frame)
		end
	end

	return #animation.parts > 0
end

function AnimatedHandTool:loadAnimationPartFromXMLFile(xmlFile, key, part, components, i3dMappings)
	local node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)

	if node == nil then
		return false
	end

	part.node = node
	part.frames = {}
	local hasFrames = false

	xmlFile:iterate(key .. ".keyFrame", function (_, frameKey)
		local keyframe = {
			time = xmlFile:getValue(frameKey .. "#time"),
			AnimatedObject.loadFrameValues(self, xmlFile, frameKey, node)
		}

		table.insert(part.frames, keyframe)

		hasFrames = true
	end)

	return hasFrames
end

function AnimatedHandTool:getAnimationTime(name)
	local animation = self.animationsByName[name]

	if animation == nil then
		return
	end

	return animation.time
end

function AnimatedHandTool:isPlaying(name)
	local animation = self.animationsByName[name]

	if animation == nil then
		return
	end

	return animation.isPlaying
end

function AnimatedHandTool:setAnimationTime(name, time)
	local animation = self.animationsByName[name]

	if animation == nil then
		return
	end

	time = MathUtil.clamp(time, 0, 1)

	for _, part in pairs(animation.parts) do
		local v = part.animCurve:get(time)

		AnimatedObject.setFrameValues(self, part.node, v)
	end

	animation.time = time
	animation.isPlaying = animation.time ~= 0 and animation.time ~= 1

	if not animation.isPlaying then
		self:stopAnimation(animation.name)
	end

	return time
end

function AnimatedHandTool:playAnimation(name, speed)
	local animation = self.animationsByName[name]
	animation.speed = speed
	animation.isPlaying = true
end

function AnimatedHandTool:stopAnimation(name)
	local animation = self.animationsByName[name]
	animation.speed = nil
	animation.isPlaying = false
end

function AnimatedHandTool:update(dt)
	for _, animation in ipairs(self.animations) do
		if animation.speed ~= nil and animation.isPlaying then
			local time = animation.time + dt * animation.speed / animation.duration

			self:setAnimationTime(animation.name, time)
		end
	end
end
