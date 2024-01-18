TreeScenario = {}
local TreeScenario_mt = Class(TreeScenario, RolePlayScenario)

function TreeScenario.registerXMLPaths(xmlSchema)
end

function TreeScenario.new(customEnvironment, mission, messageCenter)
	local self = TreeScenario:superClass().new(customEnvironment, mission, messageCenter, TreeScenario_mt)
	self.tree = nil
	self.treeIndex = nil
	self.didInitialRun = false
	self.seenTreeParts = {}

	g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onTreeShapeCut, self)

	return self
end

function TreeScenario:delete()
	TreeScenario:superClass().delete(self)
	g_messageCenter:unsubscribeAll(self)

	if self.tree ~= nil and self.treeIndex ~= nil then
		table.remove(g_treePlantManager.treesData.splitTrees, self.treeIndex)

		if entityExists(self.tree.node) then
			delete(self.tree.node)
		end

		self.tree = nil
		self.treeIndex = nil
	end
end

function TreeScenario:onPlayerJoinWriteStream(streamId, connection)
	TreeScenario:superClass().onPlayerJoinWriteStream(self, streamId, connection)
end

function TreeScenario:writeStream(streamId, connection)
	TreeScenario:superClass().writeStream(self, streamId, connection)
end

function TreeScenario:onPlayerJoinReadStream(streamId, connection)
	TreeScenario:superClass().onPlayerJoinReadStream(self, streamId, connection)
end

function TreeScenario:readStream(streamId, connection)
	TreeScenario:superClass().readStream(self, streamId, connection)
end

function TreeScenario:onTargetPositionDetermined(x, y, z)
	TreeScenario:superClass().onTargetPositionDetermined(self, x, y, z)

	self.countFrames = 2
	self.activeTreeParts = {}
	self.seenTreeParts = {}

	if self.isServer then
		self:spawnTree(x, y, z)
	end

	self:countTreeParts()
end

function TreeScenario:onStart()
	TreeScenario:superClass().onStart(self)
end

function TreeScenario:isComplete()
	if self.targetPosition == nil then
		return false
	end

	if self.tree == nil then
		return false
	end

	self:countTreeParts()

	if #self.seenTreeParts <= 2 then
		return false
	end

	if #self.activeTreeParts ~= 0 then
		return false
	end

	return self.didInitialRun
end

function TreeScenario:onUpdate(dt)
	TreeScenario:superClass().onUpdate(self, dt)

	if self.tree == nil then
		return
	end

	if not self.isServer then
		return
	end

	if self.tree.frames >= 0 then
		self.tree.frames = self.tree.frames - 1

		if self.tree.frames == 0 then
			self:cutTree(self.tree)
			self:validateTreeParts()
			self:countTreeParts()
		end
	end

	if self.countFrames >= 0 then
		self.countFrames = self.countFrames - 1

		if self.countFrames == 0 then
			self.countFrames = 2

			self:validateTreeParts()

			if self.scenarioCheckPoint:hasAction() and self.scenarioCheckPoint.action:isa(ScenarioHandToolAction) then
				local seen = #self.seenTreeParts
				local active = #self.activeTreeParts
				local totalCheckPointsSteps = self.initialCheckPointsSteps + seen
				local checkpointsStepsCompleted = self.checkpointsStepsCompleted + 1
				local completedOfActive = seen - active
				local progress = (checkpointsStepsCompleted + completedOfActive) / totalCheckPointsSteps

				if RolePlayScenario.PROGRESS_PRECISION < math.abs(self.progress - progress) then
					self:setProgress(progress)
					g_server:broadcastEvent(ScenarioCheckPointProgressEvent.new(self.scenarioCheckPoint.id, progress), false)
				end
			end
		end
	end
end

function TreeScenario:spawnTree(x, y, z)
	local offset = math.min(self.size.width, self.size.length) / 2
	x = x - offset
	y = y + self.size.height / 2
	z = z - offset
	local type = nil
	local growthState = 0

	while growthState <= 3 do
		type = table.getRandomElement(g_treePlantManager.treeTypes)
		growthState = table.getn(type.treeFilenames)
	end

	local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromName(type.name)
	local treeId = g_treePlantManager:plantTree(treeTypeDesc.index, x, y, z, 0, 0, 0, growthState, nil, false, nil)

	for i, splitTree in ipairs(g_treePlantManager.treesData.splitTrees) do
		if treeId == splitTree.node then
			self.tree = splitTree
			self.treeIndex = i

			break
		end
	end

	if self.tree == nil then
		Logging.error("Unable to start tree scenario, tree is not defined!")

		return
	end

	self.tree.dirX = 2 * offset
	self.tree.dirY = 0
	self.tree.dirZ = 2 * offset
	self.tree.frames = 2
	self.tree.parts = {}
end

function TreeScenario:cutTree(tree)
	local treeId = tree.node + 2
	local x, y, z = getWorldTranslation(treeId)
	local localX, localY, localZ = worldToLocal(treeId, x, y + 0.5, z)
	local cx, cy, cz = localToWorld(treeId, localX - 2, localY, localZ - 2)
	local nx, ny, nz = localDirectionToWorld(treeId, 0, 1, 0)
	local yx, yy, yz = localDirectionToWorld(treeId, 0, 0, 1)
	self.treeShapeBeingCut = treeId

	splitShape(treeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, 4, 4, "onTreeCutSplitCallback", self)

	local finalShape = nil

	for _, p in pairs(tree.parts) do
		if p.isBelow then
			removeFromPhysics(p.shape)
			delete(p.shape)
		else
			finalShape = p.shape
		end
	end

	if finalShape ~= nil then
		removeFromPhysics(finalShape)
		setDirection(finalShape, 0, -1, 0, tree.dirX, tree.dirY, tree.dirZ)
		addToPhysics(finalShape)
	end
end

function TreeScenario:validateTreeParts()
	if self.seenTreeParts == nil then
		return
	end

	for i, id in ipairs(self.seenTreeParts) do
		if not entityExists(id) then
			table.remove(self.seenTreeParts, i)
		end
	end
end

function TreeScenario:countTreeParts()
	self.activeTreeParts = {}
	local x, y, z = unpack(self.targetPosition)

	if g_currentMission.rolePlay.isDebug then
		DebugUtil.drawOverlapBox(x, y, z, 0, 0, 0, self.size.width, self.size.height, self.size.length)
	end

	overlapBox(x, y, z, 0, 0, 0, self.size.width, self.size.height, self.size.length, "onTreeCountOverlapCallback", self)

	self.didInitialRun = true
end

function TreeScenario:onTreeCutSplitCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	rotate(shape, 0.1, 0, 0)
	g_currentMission:addKnownSplitShape(shape)
	g_treePlantManager:addingSplitShape(shape, self.treeShapeBeingCut, true)
	table.insert(self.tree.parts, {
		shape = shape,
		isBelow = isBelow,
		isAbove = isAbove,
		minY = minY,
		maxY = maxY,
		minZ = minZ,
		maxZ = maxZ
	})
end

function TreeScenario:onTreeCountOverlapCallback(objectId, ...)
	if not entityExists(objectId) or not getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) then
		return
	end

	if getSplitType(objectId) == 0 then
		return
	end

	local isSplit = getIsSplitShapeSplit(objectId)
	local isStatic = getRigidBodyType(objectId) == RigidBodyType.STATIC

	if not isSplit then
		return
	end

	if isStatic then
		return
	end

	if not table.hasElement(self.seenTreeParts, objectId) then
		table.insert(self.seenTreeParts, objectId)
	end

	table.insert(self.activeTreeParts, objectId)
end

function TreeScenario:onTreeShapeCut(oldShape, shape)
	if self.isServer then
		self:validateTreeParts()
		self:countTreeParts()
	end
end
