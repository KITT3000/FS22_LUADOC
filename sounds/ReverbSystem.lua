ReverbSystem = {}
local ReverbSystem_mt = Class(ReverbSystem)

function ReverbSystem.getName(index)
	for name, id in pairs(Reverb) do
		if id == index then
			return name
		end
	end

	return nil
end

function ReverbSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or ReverbSystem_mt)
	self.mission = mission
	self.isDebugViewActive = false
	self.AREA_TYPE_TO_REVERB_TYPE = {
		[AreaType.OPEN_FIELD] = Reverb.GS_OPEN_FIELD,
		[AreaType.HALL] = Reverb.GS_INDOOR_HALL,
		[AreaType.CITY] = Reverb.GS_CITY,
		[AreaType.FOREST] = Reverb.GS_FOREST
	}
	self.blendFactor = 0
	self.reverbType1 = Reverb.GS_OPEN_FIELD
	self.reverbType2 = Reverb.GS_OPEN_FIELD
	self.targetReverbTypes = {
		{
			weight = 1,
			type = Reverb.GS_OPEN_FIELD
		},
		{
			weight = 0,
			type = Reverb.GS_OPEN_FIELD
		}
	}

	addConsoleCommand("gsReverbSystemToggleDebugView", "Toggles the reverb debug view", "consoleCommandToggleDebugView", self)

	return self
end

function ReverbSystem:delete()
	self.mission:removeDrawable(self)
	removeConsoleCommand("gsReverbSystemToggleDebugView")

	self.mission = nil
end

function ReverbSystem:update(dt)
	local areaWeights = self.mission.environmentAreaSystem:getAreaWeights()
	local reverbType1, reverbType2 = nil
	local reverbType1Weight = 0
	local reverbType2Weight = 0

	for areaTypeIndex, weight in pairs(areaWeights) do
		local reverbTypeIndex = self.AREA_TYPE_TO_REVERB_TYPE[areaTypeIndex]

		if reverbTypeIndex ~= nil then
			if reverbType1 == nil then
				reverbType1 = reverbTypeIndex
				reverbType1Weight = weight
			elseif reverbType2 == nil or reverbType2Weight < weight then
				reverbType2 = reverbTypeIndex
				reverbType2Weight = weight
			end

			if reverbType1 ~= nil and reverbType2 ~= nil and reverbType1Weight < reverbType2Weight then
				reverbType1Weight = reverbType2Weight
				reverbType2Weight = reverbType1Weight
				reverbType1 = reverbType2
				reverbType2 = reverbType1
			end
		end
	end

	reverbType1 = reverbType1 or Reverb.GS_OPEN_FIELD
	reverbType2 = reverbType2 or Reverb.GS_OPEN_FIELD
	local sum = reverbType1Weight + reverbType2Weight

	if sum == 0 then
		sum = 1
	end

	local fadeDelta = dt / 400
	self.targetReverbTypes[1].type = reverbType1
	self.targetReverbTypes[1].weight = reverbType1Weight / sum
	self.targetReverbTypes[1].name = ReverbSystem.getName(reverbType1)
	self.targetReverbTypes[2].type = reverbType2
	self.targetReverbTypes[2].name = ReverbSystem.getName(reverbType2)
	self.targetReverbTypes[2].weight = reverbType2Weight / sum
	local areEqual = self.reverbType1 == self.reverbType2
	local isFirstTypeCorrect = self.reverbType1 == self.targetReverbTypes[1].type or self.reverbType1 == self.targetReverbTypes[2].type
	local isSecondTypeCorrect = not areEqual and self.reverbType2 == self.targetReverbTypes[1].type or self.reverbType2 == self.targetReverbTypes[2].type
	local newReverbType1 = self.reverbType1
	local newReverbType2 = self.reverbType2

	if isFirstTypeCorrect and isSecondTypeCorrect then
		local targetBlendFactor = 1 - self.targetReverbTypes[1].weight

		if self.reverbType1 ~= self.targetReverbTypes[1].type then
			targetBlendFactor = self.targetReverbTypes[1].weight
		end

		if targetBlendFactor < self.blendFactor then
			self.blendFactor = math.max(self.blendFactor - fadeDelta, targetBlendFactor)
		else
			self.blendFactor = math.min(self.blendFactor + fadeDelta, targetBlendFactor)
		end
	elseif isFirstTypeCorrect then
		if self.blendFactor == 0 then
			if self.reverbType1 == self.targetReverbTypes[1].type then
				newReverbType2 = self.targetReverbTypes[2].type
			else
				newReverbType2 = self.targetReverbTypes[1].type
			end
		end

		self.blendFactor = math.max(self.blendFactor - fadeDelta, 0)
	else
		if self.blendFactor == 1 then
			if self.reverbType2 == self.targetReverbTypes[1].type then
				newReverbType1 = self.targetReverbTypes[2].type
			else
				newReverbType1 = self.targetReverbTypes[1].type
			end
		end

		self.blendFactor = math.min(self.blendFactor + fadeDelta, 1)
	end

	self.reverbType1 = newReverbType1
	self.reverbType2 = newReverbType2

	setReverbEffect(SoundManager.DEFAULT_REVERB_EFFECT, self.reverbType1, self.reverbType2, self.blendFactor)
end

function ReverbSystem:draw()
	setTextBold(false)
	setTextColor(1, 1, 1, 1)

	local type1 = self.reverbType1
	local type2 = self.reverbType2

	renderText(0.7, 0.5, 0.012, string.format("Current: %s %.3f -> %s %.3f", ReverbSystem.getName(type1), 1 - self.blendFactor, ReverbSystem.getName(type2), self.blendFactor))
	renderText(0.7, 0.45, 0.012, string.format("Target: %s %.3f -> %s %.3f", self.targetReverbTypes[1].name, self.targetReverbTypes[1].weight, self.targetReverbTypes[2].name, self.targetReverbTypes[2].weight))
end

function ReverbSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive

	if self.isDebugViewActive then
		self.mission:addDrawable(self)
	else
		self.mission:removeDrawable(self)
	end
end
