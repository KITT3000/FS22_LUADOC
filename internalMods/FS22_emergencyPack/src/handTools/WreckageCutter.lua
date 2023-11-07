WreckageCutter = {}
local WreckageCutter_mt = Class(WreckageCutter, WreckageTool)

InitObjectClass(WreckageCutter, "WreckageCutter")

function WreckageCutter.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".ringSelector#file", "Ring selector i3d file")
	schema:register(XMLValueType.FLOAT, basePath .. ".ringSelector#scaleOffset", "Ring selector scale offset", 0.3)
end

function WreckageCutter.new(isServer, isClient, customMt)
	local self = WreckageCutter:superClass().new(isServer, isClient, customMt or WreckageCutter_mt)
	self.playerInputText = g_i18n:getText("input_cutObject")
	self.workDistance = 1
	self.focusDistance = self.workDistance * 4
	self.cutNodes = {}
	self.cutNodesLoaded = false
	self.currentCutNode = 1

	return self
end

function WreckageCutter:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.isClient then
		if self.ringSelector ~= nil then
			delete(self.ringSelector)

			self.ringSelector = nil
		end

		if self.sharedLoadRequestIdRingSelector ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestIdRingSelector)

			self.sharedLoadRequestIdRingSelector = nil
		end
	end

	WreckageCutter:superClass().delete(self)
end

function WreckageCutter:postLoad(xmlFile)
	if not WreckageCutter:superClass().postLoad(self, xmlFile) then
		return false
	end

	if self.isClient then
		local filename = xmlFile:getValue("handTool.wreckage.ringSelector#file")

		if filename ~= nil then
			filename = Utils.getFilename(filename, self.baseDirectory)

			g_i3DManager:pinSharedI3DFileInCache(filename)

			self.sharedLoadRequestIdRingSelector = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.onRingSelectorLoaded, self, self.player)
		end
	end

	return true
end

function WreckageCutter:onRingSelectorLoaded(node, failedReason, args)
	if node ~= 0 then
		if not self.isDeleted then
			self.ringSelector = getChildAt(node, 0)

			setVisibility(self.ringSelector, false)
			setRotation(self.ringSelector, 0, 0, math.deg(-90))
			setScale(self.ringSelector, 1, 0.5, 0.5)
			link(self.handNode, self.ringSelector)
		end

		delete(node)
	end
end

function WreckageCutter:updateRingSelector(shape)
	if self.ringSelector ~= nil then
		local hasShape = shape ~= nil and shape ~= 0

		if hasShape and self.player == g_currentMission.player then
			if g_currentMission.rolePlay.isDebug then
				DebugUtil.drawDebugNode(self.ringSelector, "ringSelector")
			end

			local x, y, z = getWorldTranslation(shape)

			setWorldTranslation(self.ringSelector, x, y, z)

			if not getVisibility(self.ringSelector) and self.isInFocusRange then
				setVisibility(self.ringSelector, true)
			elseif getVisibility(self.ringSelector) and not self.isInFocusRange then
				setVisibility(self.ringSelector, false)
			end

			if getVisibility(self.ringSelector) then
				if self.isInWorkRange then
					setShaderParameter(self.ringSelector, "colorScale", 0.395, 0.925, 0.115, 1, false)
				else
					setShaderParameter(self.ringSelector, "colorScale", 0.098, 0.45, 0.96, 1, false)
				end
			end
		else
			setVisibility(self.ringSelector, false)
		end
	end
end

function WreckageCutter:onActivate(allowInput)
	WreckageCutter:superClass().onActivate(self, allowInput)

	if not self.cutNodesLoaded then
		local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)
		local checkpoint = scenario:getActiveCheckpoint()

		if checkpoint ~= nil and checkpoint:hasAction() then
			local action = checkpoint.action
			local ref = checkpoint:getObjectReferenceById("cutNodes")

			if ref == nil then
				return
			end

			for i = 0, getNumOfChildren(ref.node) - 1 do
				table.insert(self.cutNodes, getChildAt(ref.node, i))
			end

			self.currentCutNode = math.min(action:getCount() + 1, #self.cutNodes)
			self.cutNodesLoaded = true
		end
	end
end

function WreckageCutter:onDeactivate(allowInput)
	WreckageCutter:superClass().onDeactivate(self, allowInput)

	if self.isClient and self.ringSelector ~= nil then
		setVisibility(self.ringSelector, false)
	end
end

function WreckageCutter:update(dt, allowInput)
	WreckageCutter:superClass().update(self, dt, allowInput)

	if self.isClient then
		self:updateVisual(not self.isWorking)
	end
end

function WreckageCutter:updateTick(dt, allowInput)
	WreckageCutter:superClass().updateTick(self, dt, allowInput)
end

function WreckageCutter:isWreckageNode(nodeId, x, y, z)
	if not self.cutNodesLoaded then
		return false
	end

	local node = self.cutNodes[self.currentCutNode]
	local distance = calcDistanceFrom(node, self.handNode)

	return distance < self.workDistance
end

function WreckageCutter:setState(state, noEventSend)
	RolePlayHandToolStateEvent.sendEvent(self.player, state, noEventSend)

	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)
	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil then
		return
	end

	if not checkpoint:hasAction() then
		return
	end

	local action = checkpoint.action
	local previousCount = math.min(action:getCount() + 1, #self.cutNodes)

	g_messageCenter:publish(ScenarioMessageType.SCENARIO_CHECKPOINT_ACTION_COUNT, scenario.id)

	self.currentCutNode = math.min(previousCount + 1, #self.cutNodes)
	local isDone = self.currentCutNode == #self.cutNodes

	if self.isClient and self.ringSelector ~= nil then
		setVisibility(self.ringSelector, false)
	end

	if isDone then
		local visualRef = checkpoint:getObjectReferenceById("visual")
		local physicsRef = checkpoint:getObjectReferenceById("physics")

		setVisibility(visualRef.node, false)
		setVisibility(physicsRef.node, true)

		local physicsObjects = checkpoint:getObjectReferencePhysics(visualRef.node)

		for _, object in ipairs(physicsObjects) do
			removeFromPhysics(object)
		end

		local x, y, z = getWorldTranslation(self.player.cameraNode)

		physicsRef.object:setWorldPositionAndRotation(x, y, z, 0, 0, 0, true)

		self.hasWreckedObject = true
	end

	if self.state ~= state then
		self.state = state
	end
end

function WreckageCutter:updateVisual(doReset)
	WreckageCutter:superClass().updateVisual(self, doReset)

	if self.isActive then
		local node = self.cutNodes[self.currentCutNode]

		self:updateRingSelector(node)
	end
end
