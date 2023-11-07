ScenarioObject = {}
local ScenarioObject_mt = Class(ScenarioObject, ScenarioNode)

function ScenarioObject.new(isServer, isClient, custom_mt)
	local self = ScenarioObject:superClass().new(isServer, isClient, custom_mt or ScenarioObject_mt)
	self.sharedLoadRequestId = nil

	return self
end

function ScenarioObject:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	ScenarioObject:superClass().delete(self)
end

function ScenarioObject:readStream(streamId, connection)
	if connection:getIsServer() then
		local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		if self.i3dFilename == nil then
			self:loadFromI3DFile(i3dFilename)
		end
	end

	ScenarioObject:superClass().readStream(self, streamId, connection)
end

function ScenarioObject:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
	end

	ScenarioObject:superClass().writeStream(self, streamId, connection)
end

function ScenarioObject:loadFromXML(xmlFile, key, baseDirectory, scenarioRootNode)
	if not ScenarioObject:superClass().loadFromXML(self, xmlFile, key, baseDirectory, scenarioRootNode) then
		return false
	end

	self.startWithPhysics = xmlFile:getBool(key .. "#startWithPhysics", self.startWithPhysics)
	local index = xmlFile:getInt(key .. "#index")
	local filename = xmlFile:getString(key .. "#filename")

	if filename ~= nil then
		self:loadFromI3DFile(filename, baseDirectory, index)
	end

	return true
end

function ScenarioObject:loadFromI3DFile(i3dFilename, baseDirectory, index)
	local i3dFilePath = Utils.getFilename(i3dFilename, baseDirectory)

	if not fileExists(i3dFilePath) then
		i3dFilePath = Utils.getFilename(i3dFilename, g_currentMission.rolePlay.modDirectory)
	end

	self.i3dFilename = i3dFilePath
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilePath)
	local i3dNode, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilePath, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId
	local rootNode = getChildAt(i3dNode, index ~= nil and index or 0)

	link(getRootNode(), rootNode)
	delete(i3dNode)
	self:setNodeId(rootNode)
	self:removeFromPhysics()
end

function ScenarioObject:loadFromI3DFileAtWorldPosition(i3dFilename, index, x, y, z, rx, ry, rz, limitToGround)
	self:loadFromI3DFile(i3dFilename, nil, index)

	if limitToGround then
		y = self:getTerrainLimitedYPosition(x, y, z, self.groundYOffset)
	end

	self:setWorldPositionAndRotation(x, y, z, rx, ry, rz, limitToGround)
end

function ScenarioObject:setNodeId(nodeId)
	ScenarioObject:superClass().setNodeId(self, nodeId)

	if self.startWithPhysics then
		self:addToPhysics()
	end
end

function ScenarioObject:setWorldPosition(x, y, z, limitToGround)
	self:removeFromPhysics()
	ScenarioObject:superClass().setWorldPosition(self, x, y, z, limitToGround)
	self:addToPhysics()
end

function ScenarioObject:setWorldRotation(x, y, z)
	self:removeFromPhysics()
	ScenarioObject:superClass().setWorldRotation(self, x, y, z)
	self:addToPhysics()
end

function ScenarioObject:setWorldPositionAndRotation(x, y, z, rotX, rotY, rotZ, limitToGround)
	self:removeFromPhysics()
	ScenarioObject:superClass().setWorldPositionAndRotation(self, x, y, z, rotX, rotY, rotZ, limitToGround)
	self:addToPhysics()
end
