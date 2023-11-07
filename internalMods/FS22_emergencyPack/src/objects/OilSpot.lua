OilSpot = {}
local OilSpot_mt = Class(OilSpot, ScenarioObject)

function OilSpot.registerXMLPaths(schema, basePath)
end

function OilSpot.new(isServer, isClient, custom_mt)
	local self = OilSpot:superClass().new(isServer, isClient, custom_mt or OilSpot_mt)
	self.isThreatenState = false

	return self
end

function OilSpot:delete()
	OilSpot:superClass().delete(self)
end

function OilSpot:loadFromXML(xmlFile, key, baseDirectory, scenarioRootNode)
	if not OilSpot:superClass().loadFromXML(self, xmlFile, key, baseDirectory, scenarioRootNode) then
		return false
	end

	self.scale = math.max(math.random(25) / 10, 0.5)

	setScale(self.nodeId, self.scale, 1, self.scale)

	self.oilPositionOffset = self.positionOffset
	self.positionOffset = {
		0,
		0,
		0
	}

	return true
end

function OilSpot:setWorldPositionAndRotation(...)
	setScale(self.nodeId, 1, 1, 1)
	OilSpot:superClass().setWorldPositionAndRotation(self, ...)
	setScale(self.nodeId, self.scale, 1, self.scale)
end

function OilSpot:start()
	OilSpot:superClass().start(self)

	if self.isClient then
		local param = {
			0,
			0.5
		}

		I3DUtil.setShaderParameterRec(self.nodeId, "offsetUV", table.getRandomElement(param), table.getRandomElement(param), nil, nil)
	end

	self.node1 = createTransformGroup("node1")
	self.node2 = createTransformGroup("node2")
	self.node3 = createTransformGroup("node3")
	self.node4 = createTransformGroup("node4")
	local halfScale = self.scale * 0.5
	local x, y, z = getWorldTranslation(self.nodeId)
	local dirX, dirY, dirZ = localDirectionToWorld(self.nodeId, 0, 0, 1)
	local upX, upY, upZ = localDirectionToWorld(self.nodeId, 0, 1, 0)
	local offsets = {
		{
			y = 0,
			x = -halfScale,
			z = halfScale
		},
		{
			y = 0,
			x = halfScale,
			z = -halfScale
		},
		{
			y = 0,
			x = -halfScale,
			z = -halfScale
		},
		{
			y = 0,
			x = halfScale,
			z = halfScale
		}
	}

	for i = 1, 4 do
		local y0 = self:getTerrainLimitedYPosition(x, y + 1, z, self.groundYOffset)
		local x1, y1, z1 = MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, offsets[i].x, offsets[i].y, offsets[i].z)
		y1 = self:getTerrainLimitedYPosition(x1, y1 + 1, z1, self.groundYOffset)

		setWorldTranslation(self["node" .. i], x1, y1, z1)

		y = (y + y0 + y1) / 3
	end

	if not self.didOffset then
		self.positionOffset = self.oilPositionOffset
		self.didOffset = true
	else
		self.positionOffset = {
			0,
			0,
			0
		}
	end

	self:setWorldPosition(x, y, z)
	delete(self.node1)
	delete(self.node2)
	delete(self.node3)
	delete(self.node4)
end

function OilSpot:complete()
	OilSpot:superClass().complete(self)
end

function OilSpot:isThreaten()
	return self.isThreatenState
end

function OilSpot:setIsThreaten(isThreaten)
	self.isThreatenState = isThreaten

	I3DUtil.setShaderParameterRec(self.nodeId, "RDT", 0, 1, nil, nil)
end
