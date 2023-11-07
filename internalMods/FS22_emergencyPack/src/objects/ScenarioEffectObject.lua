ScenarioEffectObject = {}
local ScenarioEffectObject_mt = Class(ScenarioEffectObject, ScenarioObject)

function ScenarioEffectObject.registerXMLPaths(schema, basePath)
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effects")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "sample")
end

function ScenarioEffectObject.new(isServer, isClient, custom_mt)
	return ScenarioEffectObject:superClass().new(isServer, isClient, custom_mt or ScenarioEffectObject_mt)
end

function ScenarioEffectObject:delete()
	g_effectManager:deleteEffects(self.effects)
	g_soundManager:deleteSample(self.sample)
	ScenarioEffectObject:superClass().delete(self)
end

function ScenarioEffectObject:loadFromXML(xmlFile, key, baseDirectory, scenarioRootNode)
	if not ScenarioEffectObject:superClass().loadFromXML(self, xmlFile, key, baseDirectory, scenarioRootNode) then
		return false
	end

	self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", self.nodeId, self, nil)
	self.sample = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "sample", baseDirectory, self.nodeId, 0, AudioGroup.ENVIRONMENT, nil)

	g_effectManager:setFillType(self.effects, FillType.MANURE)
	g_effectManager:setFillType(self.effects, FillType.UNKNOWN)

	return true
end

function ScenarioEffectObject:start()
	g_effectManager:startEffects(self.effects)
	g_soundManager:playSample(self.sample)
	ScenarioEffectObject:superClass().start(self)
end

function ScenarioEffectObject:complete()
	g_effectManager:stopEffects(self.effects)
	g_soundManager:stopSample(self.sample)
	ScenarioEffectObject:superClass().complete(self)
end

function ScenarioEffectObject:setDensity(density)
	g_effectManager:setDensity(self.effects, density)
end
