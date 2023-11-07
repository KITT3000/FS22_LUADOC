RolePlay = {
	SCENARIO_STOP_MAX_IDLE_TIME = 60000,
	SCENARIO_PAGER_MIN_INTERVAL_TIME = 300,
	SCENARIO_PAGER_MAX_INTERVAL_TIMES = {
		600,
		900,
		1800,
		3600,
		7200,
		14400
	},
	SCENARIO_PAGER_MAX_INTERVAL_TEXTS = {
		"10 min",
		"15 min",
		"30 min",
		"1 h",
		"2 h",
		"4 h"
	}
}
local RolePlay_mt = Class(RolePlay)

function RolePlay.new(modName, modDirectory, mission, inputBinding, i18n, messageCenter, modManager)
	local self = setmetatable({}, RolePlay_mt)
	self.modName = modName
	self.modDirectory = modDirectory
	self.isDebug = false
	self.isServer = mission:getIsServer()
	self.isClient = mission:getIsClient()
	self.mission = mission
	self.inputBinding = inputBinding
	self.i18n = i18n
	self.messageCenter = messageCenter
	self.thirdPartyMods = RolePlayThirdPartyMods.new(modManager, modDirectory, mission)
	self.scenarioStartEntriesByType = {}
	self.handTools = {}
	self.vehicles = {}
	self.scenarioPools = {}
	self.scenarioReferences = {}
	self.scenarios = {}
	self.runningScenarios = {}
	self.pendingScenarios = {}
	self.pendingRemovalScenarios = {}
	self.requestedScenarios = {}
	self.stateMachines = {}

	if self.isServer and g_addCheatCommands then
		addConsoleCommand("epToggleDebug", "Toggle role play debug mode", "consoleCommandToggleDebug", self)
	end

	self.messageCenter:subscribe(ScenarioMessageType.SCENARIO_TOGGLE, self.onScenarioToggleForFarm, self)
	self.messageCenter:subscribe(ScenarioMessageType.SCENARIO_START_STOP, self.startStopScenarioForFarm, self)
	self.messageCenter:subscribe(ScenarioMessageType.SCENARIO_PENDING, self.onRequestedScenarioForFarm, self)
	self.messageCenter:subscribe(ScenarioMessageType.SCENARIO_DETERMINED, self.onScenarioDeterminedForFarm, self)
	self.messageCenter:subscribe(ScenarioMessageType.STATEMACHINE_TRANSITION, self.onStateMachineTransition, self)

	local title = g_i18n:getText("settings_title", self.customEnvironment)
	self.settings = AdditionalSettingsManager.new(title, self, modName, modDirectory)
	title = g_i18n:getText("settings_maxInterval_title", self.customEnvironment)
	local tooltip = g_i18n:getText("settings_maxInterval_tooltip", self.customEnvironment)

	self.settings:addSetting("ROLEPLAY_PAGER_MAX_INTERVAL", AdditionalSettingsManager.TYPE_MULTIBOX, title, tooltip, 1, RolePlay.SCENARIO_PAGER_MAX_INTERVAL_TEXTS)

	title = g_i18n:getText("settings_pagerActivated_title", self.customEnvironment)
	tooltip = g_i18n:getText("settings_pagerActivated_tooltip", self.customEnvironment)

	self.settings:addSetting("ROLEPLAY_PAGER_ACTIVATED", AdditionalSettingsManager.TYPE_CHECKBOX, title, tooltip, true)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED.ROLEPLAY_PAGER_ACTIVATED, self.onPagerStateChanged, self)

	return self
end

function RolePlay:load()
	self:buildScenarios()
end

function RolePlay:delete()
	removeConsoleCommand("epToggleDebug")
	self.thirdPartyMods:delete()

	for farmId, _ in pairs(self.runningScenarios) do
		self:clearScenarioForFarm(farmId)
	end
end

function RolePlay:onMissionLoaded(mission)
	self.thirdPartyMods:load()
	self:load()
end

function RolePlay:onConnectionFinishedLoading(connection)
	connection:sendEvent(RolePlayConnectToServerEvent.new())
end

function RolePlay:writeStream(streamId, connection)
	local numRunningScenarios = table.getn(self.runningScenarios)

	streamWriteUInt8(streamId, numRunningScenarios)

	for farmId, scenario in pairs(self.runningScenarios) do
		streamWriteUIntN(streamId, farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteInt32(streamId, scenario.id)
	end

	for _, scenario in pairs(self.runningScenarios) do
		scenario:onPlayerJoinWriteStream(streamId, connection)
	end

	for _, stateMachine in pairs(self.stateMachines) do
		stateMachine:writeStream(streamId, connection)
	end
end

function RolePlay:readStream(streamId, connection)
	local numRunningScenarios = streamReadUInt8(streamId)
	self.pendingScenarios = {}

	for _ = 1, numRunningScenarios do
		local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local scenarioId = streamReadInt32(streamId)
		local scenario = self:loadScenarioByInfoId(scenarioId, farmId)
		self.pendingScenarios[farmId] = scenario

		self:startScenarioForFarm(farmId)
	end

	for _, scenario in pairs(self.runningScenarios) do
		scenario:onPlayerJoinReadStream(streamId, connection)
	end

	for _, stateMachine in pairs(self.stateMachines) do
		stateMachine:readStream(streamId, connection)
	end
end

function RolePlay:update(dt)
	if self.isServer then
		for farmId, scenario in pairs(self.runningScenarios) do
			local stateMachine = self.stateMachines[farmId]

			if stateMachine ~= nil and stateMachine:isInState(StateIds.BASE_STOP) then
				if scenario:isComplete() and not self.pendingRemovalScenarios[farmId] then
					self:setScenarioPendingRemovalForFarm(farmId)
				end

				local removal = self.pendingRemovalScenarios[farmId]

				if removal ~= nil then
					if removal.time > 0 then
						removal.time = math.max(0, removal.time - dt)
					elseif removal.isPending then
						self:startStopScenarioForFarm(farmId, scenario.id, false)
					end
				end
			end
		end
	end

	for _, stateMachine in pairs(self.stateMachines) do
		stateMachine:update(dt)
	end

	local pagerActivated = self.settings:getSetting("ROLEPLAY_PAGER_ACTIVATED")

	if pagerActivated and self.isServer and self.pagerTimer == nil then
		local pagerMaxTimeKey = self.settings:getSetting("ROLEPLAY_PAGER_MAX_INTERVAL")
		local maxTime = RolePlay.SCENARIO_PAGER_MAX_INTERVAL_TIMES[pagerMaxTimeKey]
		self.pagerTimer = Timer.createOneshot(math.random(RolePlay.SCENARIO_PAGER_MIN_INTERVAL_TIME, maxTime) * 1000, function ()
			self:onPagerScenario()
		end)
	end
end

function RolePlay:onPagerStateChanged(state)
	if not self.isServer then
		return
	end

	if not state and self.pagerTimer ~= nil then
		self.pagerTimer:delete()

		self.pagerTimer = nil
	end
end

function RolePlay:onPagerScenario()
	if not self.isServer then
		return
	end

	if #self.vehicles == 0 then
		return
	end

	local pagerActivated = self.settings:getSetting("ROLEPLAY_PAGER_ACTIVATED")

	if not pagerActivated then
		self.pagerTimer:delete()

		self.pagerTimer = nil

		return
	end

	local pagerFarmIds = {}

	for _, farm in ipairs(g_farmManager:getFarms()) do
		if not farm.isSpectator and farm:getNumActivePlayers() > 0 and self.stateMachines[farm.farmId] == nil and self.runningScenarios[farm.farmId] == nil and (self.requestedScenarios[farm.farmId] == nil or self.requestedScenarios[farm.farmId] == "none") then
			table.insert(pagerFarmIds, farm.farmId)
		end
	end

	Utils.shuffle(pagerFarmIds)

	local farmId = pagerFarmIds[1]

	if farmId ~= nil then
		self:onRequestedScenarioForFarm(farmId)
	end

	self.pagerTimer:delete()

	self.pagerTimer = nil
end

function RolePlay:onStateMachineTransition(farmId, type, stateId, params)
	local stateMachine = self.stateMachines[farmId]

	assert(stateMachine ~= nil, ("StateMachine can't be nil for farmId %s"):format(farmId))
	stateMachine:run(type, stateId, params, true)
end

function RolePlay:addHandTool(filename)
	self.handTools[filename] = true
end

function RolePlay:addVehicle(vehicle)
	table.addElement(self.vehicles, vehicle)
end

function RolePlay:removeVehicle(vehicle)
	table.removeElement(self.vehicles, vehicle)
end

function RolePlay:getVehicles()
	return self.vehicles
end

function RolePlay:getClosestVehicle(node, farmId)
	local closestVehicle = nil
	local closestDistance = math.huge

	for _, vehicle in ipairs(self.vehicles) do
		if vehicle:getOwnerFarmId() == farmId then
			local distance = calcDistanceFrom(vehicle.rootNode, node)

			if distance < closestDistance then
				closestDistance = distance
				closestVehicle = vehicle
			end
		end
	end

	return closestVehicle, closestDistance
end

function RolePlay:getHandTools()
	return self.handTools
end

function RolePlay:getRunningScenarioForFarm(farmId)
	return self.runningScenarios[farmId]
end

function RolePlay:getPendingScenarioForFarm(farmId)
	return self.pendingScenarios[farmId]
end

function RolePlay:getScenarioPaths(filename)
	local paths = self.thirdPartyMods:getScenarioPaths(filename)
	local path = Utils.getFilename("data/scenarios" .. filename, self.modDirectory)

	if fileExists(path) then
		table.insert(paths, 1, {
			file = path,
			modDir = self.modDirectory
		})
	end

	return paths
end

function RolePlay:buildScenarios()
	local scenarios = {}
	local paths = self:getScenarioPaths("/init.xml")
	local isMultiplayer = self.mission.missionDynamicInfo.isMultiplayer

	for _, path in ipairs(paths) do
		Logging.devInfo("EmergencyPack: loading scenarios from %s", path.file)

		local initXmlFile = XMLFile.load("rolePlay", path.file)

		initXmlFile:iterate("rolePlay.pools.pool", function (_, key)
			local poolName = initXmlFile:getString(key .. "#name")
			self.scenarioPools[poolName] = {}
		end)
		initXmlFile:iterate("rolePlay.scenarios.scenario", function (_, key)
			local type = initXmlFile:getString(key .. "#type")
			local forMp = initXmlFile:getBool(key .. "#mp", true)
			local scenarioPath = initXmlFile:getString(key .. "#path")
			local scenarioPools = initXmlFile:getVector(key .. "#pools")

			if forMp or not isMultiplayer and not forMp then
				table.insert(scenarios, {
					type = type,
					path = Utils.getFilename(scenarioPath, path.modDir),
					modDir = path.modDir,
					pools = scenarioPools
				})
			end
		end)

		for _, info in ipairs(scenarios) do
			for _, pool in ipairs(info.pools) do
				assert(self.scenarioPools[pool] ~= nil, "Scenario pool not found!")
				table.insert(self.scenarioPools[pool], info)
			end

			table.insert(self.scenarioReferences, info)

			info.id = #self.scenarioReferences
		end

		initXmlFile:delete()
	end
end

function RolePlay:loadScenarioByInfoId(infoId, farmId)
	local info = self.scenarioReferences[infoId]

	return self:loadScenarioByInfo(info, farmId)
end

function RolePlay:loadScenarioByInfo(info, farmId)
	local director = ScenarioDirector.new(self.mission, self.messageCenter)
	local name = Utils.getFilenameInfo(info.path)
	local xmlFile = XMLFile.load(name, info.path, ScenarioDirector.xmlSchema)
	local customEnvironment, _ = Utils.getModNameAndBaseDirectory(info.path)
	local scenario = director:makeForType(info.type, xmlFile, info.modDir, customEnvironment)
	scenario.id = info.id
	scenario.farmId = farmId

	table.insert(self.scenarios, scenario)
	xmlFile:delete()
	director:delete()

	return scenario
end

function RolePlay:determineScenario(pool)
	local scenarios = self.scenarioReferences

	if pool ~= nil and pool ~= "none" then
		assert(self.scenarioPools[pool] ~= nil, "Trying to access non existing scenario pool!")

		scenarios = self.scenarioPools[pool]
	end

	return scenarios[math.random(#scenarios)]
end

function RolePlay:setScenarioPendingRemovalForFarm(farmId)
	self.pendingRemovalScenarios[farmId] = {
		isPending = true,
		time = RolePlay.SCENARIO_STOP_MAX_IDLE_TIME
	}
end

function RolePlay:setupStateMachine(farmId, scenario)
	local builder = FiniteStateMachineBuilder.new(farmId, self.isServer)
	local stateMachine = builder:stateMachine():withScenario(scenario):addInitialState(StateIds.BASE_START, StartState):addState(StateIds.BASE_RUN, RunState):addState(StateIds.BASE_STOP, StopState):addState(StateIds.BASE_ABORT, AbortState):build()

	builder:delete()

	return stateMachine
end

function RolePlay:onRequestedScenarioForFarm(farmId, pool, userId)
	if self.isServer then
		pool = pool or "none"
		self.requestedScenarios[farmId] = pool

		self:determineScenarioForFarm(farmId, userId)
	end
end

function RolePlay:determineScenarioForFarm(farmId, userId)
	if self.isServer then
		local pool = self.requestedScenarios[farmId]
		local info = self:determineScenario(pool)

		self:onScenarioDeterminedForFarm(farmId, info.id, userId)
		g_server:broadcastEvent(ScenarioPendingEvent.new(farmId, info.id, userId), false)
	end
end

function RolePlay:onScenarioDeterminedForFarm(farmId, scenarioId, userId)
	local scenario = self:loadScenarioByInfoId(scenarioId, farmId)
	self.pendingScenarios[farmId] = scenario

	if ((userId == nil or userId == -1) and (self.isServer or self.mission.isMasterUser) or userId == g_currentMission.playerUserId) and self.isClient then
		g_gui:showYesNoDialog({
			dialogType = DialogElement.TYPE_QUESTION,
			text = self.i18n:getText("info_participate"):format(scenario.description),
			callback = function (yes)
				if self.isServer then
					self:startStopScenarioForFarm(farmId, scenarioId, yes)
				else
					g_client:getServerConnection():sendEvent(ScenarioParticipateEvent.new(farmId, scenarioId, yes))
				end
			end
		})
	end
end

function RolePlay:startStopScenarioForFarm(farmId, scenarioId, start, noEventSend)
	if self.isServer and not noEventSend then
		g_server:broadcastEvent(ScenarioStartStopEvent.new(farmId, scenarioId, start), false)
	end

	if start then
		self:startScenarioForFarm(farmId)
	else
		self:stopScenarioForFarm(farmId)
	end
end

function RolePlay:clearScenarioForFarm(farmId)
	local stateMachine = self.stateMachines[farmId]

	if stateMachine ~= nil then
		stateMachine:delete()

		self.stateMachines[farmId] = nil
	end

	self.runningScenarios[farmId] = nil
	self.pendingRemovalScenarios[farmId] = nil
end

function RolePlay:startScenarioForFarm(farmId)
	local stateMachine = self.stateMachines[farmId]

	if stateMachine ~= nil and not stateMachine:isInState(StateIds.BASE_STOP) then
		stateMachine:transition(StateIds.BASE_STOP, nil, true)
	end

	self:clearScenarioForFarm(farmId)

	local pendingScenario = self.pendingScenarios[farmId]
	stateMachine = self:setupStateMachine(farmId, pendingScenario)
	self.stateMachines[farmId] = stateMachine
	self.runningScenarios[farmId] = pendingScenario
	self.pendingScenarios[farmId] = nil
	self.requestedScenarios[farmId] = nil

	stateMachine:transition(StateIds.BASE_START, nil, true)
end

function RolePlay:stopScenarioForFarm(farmId)
	local pendingScenario = self.pendingScenarios[farmId]

	if pendingScenario ~= nil then
		pendingScenario:delete()

		self.pendingScenarios[farmId] = nil
	end

	local stateMachine = self.stateMachines[farmId]

	if stateMachine ~= nil and not stateMachine:isInState(StateIds.BASE_STOP) then
		stateMachine:transition(StateIds.BASE_STOP, nil, true)
	end

	self:clearScenarioForFarm(farmId)
end

function RolePlay:onScenarioToggleForFarm(farmId, pool, startedByUser)
	local runningScenario = self.runningScenarios[farmId]

	if runningScenario ~= nil then
		if self.isClient then
			g_gui:showYesNoDialog({
				dialogType = DialogElement.TYPE_QUESTION,
				text = self.i18n:getText("info_scenario_stop"),
				callback = function (yes)
					if yes then
						if self.isServer then
							self:startStopScenarioForFarm(farmId, runningScenario.id, false)
						else
							g_client:getServerConnection():sendEvent(ScenarioParticipateEvent.new(farmId, runningScenario.id, false))
						end
					end
				end
			})
		end
	else
		local userId = -1

		if startedByUser then
			userId = g_currentMission.playerUserId
		end

		if self.isServer then
			self:onRequestedScenarioForFarm(farmId, pool, userId)
		else
			g_client:getServerConnection():sendEvent(ScenarioRequestEvent.new(farmId, pool, userId))
		end
	end
end

function RolePlay:consoleCommandToggleDebug()
	self.isDebug = not self.isDebug

	return "Debug enabled: " .. tostring(self.isDebug)
end

function RolePlay:addStartEntry(nodeId)
	local startEntry = {
		nodeId = nodeId,
		pool = getUserAttribute(nodeId, "pool") or "unknown",
		type = getUserAttribute(nodeId, "type") or StartStrategyDirector.TYPE_MARKER
	}

	setVisibility(nodeId, false)

	if self.scenarioStartEntriesByType[startEntry.type] == nil then
		self.scenarioStartEntriesByType[startEntry.type] = {}
	end

	table.insert(self.scenarioStartEntriesByType[startEntry.type], startEntry)
end
