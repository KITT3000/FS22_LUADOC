ScenarioAction = {}
local ScenarioAction_mt = Class(ScenarioAction)

function ScenarioAction.registerXMLPaths(schema, basePath)
	ScenarioHandToolAction.registerXMLPaths(schema, basePath)
	InTriggerAction.registerXMLPaths(schema, basePath)
end

function ScenarioAction.new(checkpoint, custom_mt)
	local self = setmetatable({}, custom_mt or ScenarioAction_mt)
	self.checkpoint = checkpoint
	self.objectReferenceChanges = {}
	self.completed = false

	return self
end

function ScenarioAction:delete()
end

function ScenarioAction:readStream(streamId, connection)
end

function ScenarioAction:writeStream(streamId, connection)
end

function ScenarioAction:writeUpdateStream(streamId, connection, dirtyMask)
end

function ScenarioAction:readUpdateStream(streamId, timestamp, connection)
end

function ScenarioAction:loadFromXML(xmlFile, baseKey, baseDirectory, rootNode)
	self.rootNode = rootNode
	self.objectReferenceId = xmlFile:getString(baseKey .. "#objectReferenceId")

	xmlFile:iterate(baseKey .. ".objectReferenceChanges.change", function (_, key)
		local entry = self:loadObjectReferenceChangesFromXML(xmlFile, key)

		table.insert(self.objectReferenceChanges, entry)
	end)

	local entry = self:loadObjectReferenceChangesFromXML(xmlFile, baseKey)

	table.insert(self.objectReferenceChanges, entry)

	return true
end

function ScenarioAction:loadObjectReferenceChangesFromXML(xmlFile, baseKey)
	local entry = {
		objectReferenceId = xmlFile:getString(baseKey .. "#objectReferenceId"),
		toggleObjectReferenceVisibility = xmlFile:getBool(baseKey .. "#toggleVisibility", false),
		setObjectReferenceVisibilityAtStart = xmlFile:getBool(baseKey .. "#setVisibilityAtStart", false),
		setObjectReferenceInvisibilityAtStart = xmlFile:getBool(baseKey .. "#setInvisibilityAtStart", false),
		setObjectReferenceVisibilityAtComplete = xmlFile:getBool(baseKey .. "#setVisibilityAtComplete", false),
		setObjectReferenceInvisibilityAtComplete = xmlFile:getBool(baseKey .. "#setInvisibilityAtComplete", false)
	}

	return entry
end

function ScenarioAction:onUpdate(dt)
end

function ScenarioAction:setIsActive(isActive)
	for _, change in ipairs(self.objectReferenceChanges) do
		if change.objectReferenceId ~= nil then
			local ref = self.checkpoint:getObjectReferenceById(change.objectReferenceId)

			assert(ref ~= nil, ("Scenario action: wrong object reference used '%s'"):format(change.objectReferenceId))

			local physicsObjects = self.checkpoint:getObjectReferencePhysics(ref.node)

			if isActive then
				if change.toggleObjectReferenceVisibility or change.setObjectReferenceVisibilityAtStart then
					setVisibility(ref.node, true)

					for _, object in ipairs(physicsObjects) do
						addToPhysics(object)
					end
				elseif change.setObjectReferenceInvisibilityAtStart then
					setVisibility(ref.node, false)

					for _, object in ipairs(physicsObjects) do
						removeFromPhysics(object)
					end
				end
			elseif change.toggleObjectReferenceVisibility and not change.setObjectReferenceVisibilityAtComplete then
				setVisibility(ref.node, false)

				for _, object in ipairs(physicsObjects) do
					removeFromPhysics(object)
				end
			elseif change.setObjectReferenceVisibilityAtComplete then
				setVisibility(ref.node, true)

				for _, object in ipairs(physicsObjects) do
					addToPhysics(object)
				end
			elseif change.setObjectReferenceInvisibilityAtComplete then
				setVisibility(ref.node, false)

				for _, object in ipairs(physicsObjects) do
					removeFromPhysics(object)
				end
			end
		end
	end
end

function ScenarioAction:onStart()
	self:setIsCompleted(false)
end

function ScenarioAction:onComplete()
end

function ScenarioAction:setIsCompleted(isCompleted)
	self.completed = isCompleted
end

function ScenarioAction:isCompleted()
	return self.completed
end

function ScenarioAction:canBeCompleted()
	return false
end
