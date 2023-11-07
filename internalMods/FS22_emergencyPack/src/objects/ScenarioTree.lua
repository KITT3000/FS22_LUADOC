ScenarioTree = {}
local ScenarioTree_mt = Class(ScenarioTree, ScenarioNode)

function ScenarioTree.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Tree type name")
end

function ScenarioTree.new(isServer, isClient, custom_mt)
	local self = ScenarioTree:superClass().new(isServer, isClient, custom_mt or ScenarioTree_mt)

	return self
end

function ScenarioTree:delete()
	self:unloadTree()
	ScenarioTree:superClass().delete(self)
end

function ScenarioTree:loadFromXML(xmlFile, key, baseDirectory, scenarioRootNode)
	if not ScenarioTree:superClass().loadFromXML(self, xmlFile, key, baseDirectory, scenarioRootNode) then
		return false
	end

	self.treeType = xmlFile:getValue(key .. "#type", "oak")

	self:load()

	return true
end

function ScenarioTree:start()
	ScenarioTree:superClass().start(self)

	if self.tree == nil then
		self:loadTree()
	end
end

function ScenarioTree:loadTree()
	local treeDesc = g_treePlantManager:getTreeTypeDescFromName(self.treeType)

	if treeDesc == nil then
		Logging.error("Tree type %s does not exist", self.treeType)

		return
	end

	self.treeFilename = treeDesc.treeFilenames[table.getn(treeDesc.treeFilenames)]

	if self.treeFilename == nil then
		Logging.error("Tree type %s does not have stage %d", self.treeType, self.treeStage)

		return
	end

	self.treeTypeIndex = treeDesc.index

	setSplitShapesLoadingFileId(-1)
	setSplitShapesNextFileId(true)

	local node, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(self.treeFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId

	self:onTreeLoaded(node, failedReason)
end

function ScenarioTree:onTreeLoaded(node, failedReason)
	if node == nil or node == 0 then
		Logging.warning("Failed to load tree")

		return
	end

	link(getRootNode(), node)
	I3DUtil.setShaderParameterRec(node, "windSnowLeafScale", 0, 0, 1, 80)

	local x, y, z = getWorldTranslation(self.nodeId)
	local rx, ry, rz = getWorldRotation(self.nodeId)

	setWorldTranslation(node, x, y, z)
	setWorldRotation(node, rx, ry, rz)
	addToPhysics(node)

	self.tree = node
end

function ScenarioTree:unloadTree()
	if self.tree ~= nil then
		delete(self.tree)

		if self.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

			self.sharedLoadRequestId = nil
		end

		self.tree = nil
		self.treeFilename = nil
	end
end
