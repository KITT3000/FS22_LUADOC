ObjectReferences = {}
local ObjectReferences_mt = Class(ObjectReferences)

function ObjectReferences.new(custom_mt)
	local self = setmetatable({}, custom_mt or ObjectReferences_mt)
	self.resolveAll = false
	self.mapping = {}
	self.references = {}
	self.physicsObjects = {}

	return self
end

function ObjectReferences:delete()
	self.mapping = {}
	self.references = {}
end

function ObjectReferences:loadFromXML(xmlFile, baseKey)
	self.resolveAll = xmlFile:getBool(baseKey .. ".objectReferences#all", false)

	if self.resolveAll then
		return true
	end

	xmlFile:iterate(baseKey .. ".objectReferences.objectReference", function (_, key)
		local id = xmlFile:getString(key .. "#id")

		if id ~= nil then
			local entry = {
				id = id,
				internalId = xmlFile:getString(key .. "#internalId", id),
				nodePath = xmlFile:getString(key .. "#node")
			}

			table.insert(self.mapping, entry)
		end
	end)

	return true
end

function ObjectReferences:resolve(objectsById)
	if self.resolveAll then
		for id, object in pairs(objectsById) do
			local node = object.nodeId
			self.references[id] = {
				object = object,
				node = node
			}

			self:resolvePhysicsObjects(node, object)
		end

		return
	end

	for _, mapping in pairs(self.mapping) do
		local object = objectsById[mapping.id]

		assert(object ~= nil, ("Invalid object reference found in mapping %s"):format(mapping.id))

		local node = object.nodeId

		if mapping.nodePath ~= nil then
			node = I3DUtil.indexToObject(object.nodeId, mapping.nodePath)
		end

		self.references[mapping.internalId] = {
			object = object,
			node = node
		}

		self:resolvePhysicsObjects(node, object)
	end
end

function ObjectReferences:resolvePhysicsObjects(node, object)
	self.physicsObjects[node] = {}

	if getHasClassId(node, ClassIds.SHAPE) then
		local rigidBodyType = getRigidBodyType(node)

		if rigidBodyType ~= RigidBodyType.NONE then
			self.references[node] = {
				object = object,
				node = node
			}

			table.insert(self.physicsObjects[node], node)
		end
	end

	for i = 0, getNumOfChildren(node) - 1 do
		self:resolvePhysicsChildren(getChildAt(node, i), node, object)
	end
end

function ObjectReferences:resolvePhysicsChildren(node, parent, object)
	if getHasClassId(node, ClassIds.SHAPE) then
		local rigidBodyType = getRigidBodyType(node)

		if rigidBodyType ~= RigidBodyType.NONE then
			self.references[node] = {
				object = object,
				node = node
			}

			table.insert(self.physicsObjects[parent], node)
		end
	end
end

function ObjectReferences:getById(id)
	return self.references[id]
end

function ObjectReferences:getAll()
	return self.references
end

function ObjectReferences:getPhysicsObjects(node)
	return self.physicsObjects[node]
end
