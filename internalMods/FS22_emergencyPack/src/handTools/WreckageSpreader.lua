WreckageSpreader = {}
local WreckageSpreader_mt = Class(WreckageSpreader, WreckageTool)

InitObjectClass(WreckageSpreader, "WreckageSpreader")

function WreckageSpreader.new(isServer, isClient, customMt)
	local self = WreckageSpreader:superClass().new(isServer, isClient, customMt or WreckageSpreader_mt)
	self.playerInputText = g_i18n:getText("input_spreadObject")
	self.originalMaterial = nil
	self.lastMaterial = 0
	self.visualIndicationTime = 0
	self.visualIndicationTimeThreshold = 1000

	return self
end

function WreckageSpreader:onActivate(allowInput)
	WreckageSpreader:superClass().onActivate(self, allowInput)
end

function WreckageSpreader:onDeactivate(allowInput)
	WreckageSpreader:superClass().onDeactivate(self, allowInput)

	if self.isClient then
		self.visualIndicationTime = 0

		self:updateVisual(true)
	end
end

function WreckageSpreader:update(dt, allowInput)
	WreckageSpreader:superClass().update(self, dt, allowInput)

	if self.isClient then
		if not self.isWorking then
			self.visualIndicationTime = self.visualIndicationTime + dt
		else
			self:updateVisual(true)
		end

		if self.visualIndicationTimeThreshold <= self.visualIndicationTime then
			self.visualIndicationTime = 0

			self:updateVisual(false)
		end
	end
end

function WreckageSpreader:updateVisual(doReset)
	WreckageSpreader:superClass().updateVisual(self, doReset)

	local scenario = self.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario == nil then
		return
	end

	local checkpoint = scenario:getActiveCheckpoint()

	if checkpoint == nil then
		return
	end

	local ref = checkpoint:getObjectReferenceById("visual")

	if ref == nil then
		return
	end

	if g_currentMission.rolePlay.isDebug then
		DebugUtil.drawDebugNode(ref.node, getName(ref.node))
	end

	if getHasShaderParameter(ref.node, "colorMat0") then
		if self.originalMaterial == nil then
			local r, g, b, a = getShaderParameter(ref.node, "colorMat0")
			self.originalMaterial = a
			self.originalColors = {
				r,
				g,
				b
			}
		end

		local useOriginal = self.lastMaterial == 0
		self.lastMaterial = useOriginal and self.originalMaterial or 0
		local r = 1
		local g = 0
		local b = 0

		if useOriginal then
			r, g, b = unpack(self.originalColors)
		end

		if doReset then
			self.lastMaterial = self.originalMaterial
			r, g, b = unpack(self.originalColors)
		end

		setShaderParameter(ref.node, "colorMat0", r, g, b, self.lastMaterial, false)
	end
end
