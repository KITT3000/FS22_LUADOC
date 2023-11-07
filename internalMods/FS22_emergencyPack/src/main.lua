local isEditor = g_isEditor or false
local isIsIconGenerator = g_iconGenerator ~= nil or false
local isRunByTool = isEditor or isIsIconGenerator
local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"
local modEnvironment = nil
local sourceFiles = {
	"src/common/collection/Queue.lua",
	"src/common/collection/Stack.lua",
	"src/common/utilities/ClassExtension.lua",
	"src/common/utilities/FileExtensions.lua",
	"src/common/ObjectReferences.lua",
	"src/fsm/events/FiniteStateMachineStateEvent.lua",
	"src/fsm/states/StateIds.lua",
	"src/fsm/states/AbstractState.lua",
	"src/fsm/states/AbortState.lua",
	"src/fsm/states/StartState.lua",
	"src/fsm/states/StopState.lua",
	"src/fsm/states/RunState.lua",
	"src/fsm/FiniteStateMachine.lua",
	"src/fsm/FiniteStateMachineBuilder.lua",
	"src/specializations/events/SetCurrentEmergencySoundEvent.lua",
	"src/specializations/events/SetEmergencySoundEvent.lua",
	"src/specializations/events/SetWarningLightsEvent.lua",
	"src/objects/AnimatedHandTool.lua",
	"src/handTools/events/AttackNozzleExtinguishingFireEvent.lua",
	"src/handTools/events/WreckageToolWreckEvent.lua",
	"src/handTools/events/WreckageToolWorkEvent.lua",
	"src/handTools/events/WreckageToolStateEvent.lua",
	"src/handTools/events/RolePlayHandToolStateEvent.lua",
	"src/handTools/RolePlayHandTool.lua",
	"src/handTools/WreckageTool.lua",
	"src/handTools/WreckageCutter.lua",
	"src/handTools/WreckageSpreader.lua",
	"src/handTools/PlacementTool.lua",
	"src/handTools/InRangeActionTool.lua",
	"src/handTools/AttackNozzle.lua",
	"src/handTools/InRangeMultiActionTool.lua",
	"src/handTools/EmergencyChainsaw.lua",
	"src/objects/ScenarioNode.lua",
	"src/objects/ScenarioObject.lua",
	"src/objects/ScenarioEffectObject.lua",
	"src/objects/OilSpot.lua",
	"src/objects/ScenarioTree.lua",
	"src/triggers/RolePlayScenarioTrigger.lua",
	"src/scenarios/events/ScenarioParticipateEvent.lua",
	"src/scenarios/events/ScenarioPendingEvent.lua",
	"src/scenarios/events/ScenarioStartStopEvent.lua",
	"src/scenarios/events/ScenarioRequestEvent.lua",
	"src/scenarios/events/ScenarioAbortedEvent.lua",
	"src/scenarios/events/ScenarioCompleteEvent.lua",
	"src/scenarios/events/ScenarioCheckPointEvent.lua",
	"src/scenarios/events/ScenarioCheckPointProgressEvent.lua",
	"src/scenarios/events/ScenarioTargetPositionEvent.lua",
	"src/scenarios/events/ScenarioObjectAtWorldPositionEvent.lua",
	"src/scenarios/events/ScenarioCheckPointActionEvent.lua",
	"src/scenarios/builder/ScenarioBuilder.lua",
	"src/scenarios/builder/ScenarioDirector.lua",
	"src/scenarios/checkpoints/ScenarioCheckpoint.lua",
	"src/scenarios/actions/ScenarioAction.lua",
	"src/scenarios/actions/ScenarioHandToolAction.lua",
	"src/scenarios/actions/CompletableHandToolAction.lua",
	"src/scenarios/actions/PlaceObjectAction.lua",
	"src/scenarios/actions/InTriggerAction.lua",
	"src/scenarios/actions/FromVehicleAction.lua",
	"src/scenarios/actions/CountAction.lua",
	"src/scenarios/startStrategies/StartStrategy.lua",
	"src/scenarios/startStrategies/StartStrategySpline.lua",
	"src/scenarios/startStrategies/StartStrategyField.lua",
	"src/scenarios/startStrategies/StartStrategySellingPoints.lua",
	"src/scenarios/startStrategies/StartStrategyForest.lua",
	"src/scenarios/startStrategies/StartStrategyMarkerNode.lua",
	"src/scenarios/startStrategies/StartStrategyDirector.lua",
	"src/scenarios/startStrategies/StartStrategyVerge.lua",
	"src/scenarios/RolePlayScenario.lua",
	"src/scenarios/FireScenario.lua",
	"src/scenarios/TreeScenario.lua",
	"src/environment/events/FireObjectAtWorldPositionEvent.lua",
	"src/environment/events/FireObjectExtinguishedEvent.lua",
	"src/environment/events/FireObjectStageChangedEvent.lua",
	"src/environment/FireObject.lua",
	"src/environment/AdaptiveFire.lua",
	"src/misc/AdditionalSettingsManager.lua",
	"src/events/RolePlayConnectToServerEvent.lua",
	"src/ScenarioMessageTypes.lua",
	"src/RolePlayThirdPartyMods.lua",
	"src/RolePlay.lua"
}

for _, file in ipairs(sourceFiles) do
	source(modDirectory .. file)
end

local function isLoaded()
	return modEnvironment ~= nil and g_modIsLoaded[modName]
end

local function load(mission)
	assert(modEnvironment == nil)
	g_particleSystemManager:addParticleType("fire")
	registerHandTool("placementTool", PlacementTool)
	registerHandTool("wreckageCutter", WreckageCutter)
	registerHandTool("wreckageSpreader", WreckageSpreader)
	registerHandTool("attackNozzle", AttackNozzle)
	registerHandTool("inRangeActionTool", InRangeActionTool)
	registerHandTool("inRangeMultiActionTool", InRangeMultiActionTool)
	registerHandTool("emergencyChainsaw", EmergencyChainsaw)

	modEnvironment = RolePlay.new(modName, modDirectory, mission, g_inputBinding, g_i18n, g_messageCenter, g_modManager)
	mission.rolePlay = modEnvironment

	addModEventListener(modEnvironment)
	g_onCreateUtil.addOnCreateFunction("onCreateScenarioStart", function (nodeId)
		modEnvironment:addStartEntry(nodeId)
	end)

	if modEnvironment.settings ~= nil then
		AdditionalSettingsManager.loadFromXML(modEnvironment.settings)
	end
end

local function loadedMission(mission, node)
	if not isLoaded() then
		return
	end

	if mission.cancelLoading then
		return
	end

	modEnvironment:onMissionLoaded(mission)
end

local function unload()
	if not isLoaded() then
		return
	end

	if modEnvironment ~= nil then
		modEnvironment:delete()

		modEnvironment = nil

		if g_currentMission ~= nil then
			g_currentMission.rolePlay = nil
		end
	end
end

local function onConnectionFinishedLoading(mission, superFunc, connection, x, y, z, viewDistanceCoeff)
	if not isLoaded() then
		return superFunc(mission, connection, x, y, z, viewDistanceCoeff)
	end

	superFunc(mission, connection, x, y, z, viewDistanceCoeff)
	modEnvironment:onConnectionFinishedLoading(connection)
end

local function playerStateCycleHandtoolActivate(self, superFunc)
	PlayerStateCycleHandtool:superClass().activate(self)

	local scenario = g_currentMission.rolePlay:getRunningScenarioForFarm(self.player.farmId)

	if scenario ~= nil then
		self.rolePlay_doHandToolReset = true
		local checkpoint = scenario:getActiveCheckpoint()

		if checkpoint == nil or not checkpoint:hasAction() then
			self:deactivate()

			return
		end

		local action = checkpoint.action

		if not action.canCycleHandTool then
			self:deactivate()

			return
		end

		local farm = g_farmManager:getFarmById(self.player.farmId)
		local handTools = farm.handTools
		local currentId = 0

		if self.player:hasHandtoolEquipped() then
			local currentConfigFileName = self.player.baseInformation.currentHandtool.configFileName

			for key, filename in pairs(handTools) do
				if filename:lower() == currentConfigFileName:lower() then
					currentId = key

					break
				end
			end
		end

		currentId = currentId + self.cycleDirection

		if currentId > #handTools then
			currentId = 0
		elseif currentId < 0 then
			currentId = #handTools
		end

		if currentId == 0 then
			action:unEquipHandTool(self.player)
		else
			action:equipHandTool(self.player)
		end

		self:deactivate()
	else
		if self.rolePlay_doHandToolReset then
			self.rolePlay_doHandToolReset = false
			local rolePlayHandTools = g_currentMission.rolePlay:getHandTools()

			for xmlFilename, _ in pairs(rolePlayHandTools) do
				g_farmManager:getFarmById(self.player.farmId):removeHandTool(xmlFilename)
			end
		end

		superFunc(self)
	end
end

local function farmSaveToXMLFile(farm, superFunc, xmlFile, key)
	local originalHandTools = farm.handTools
	farm.handTools = {}
	local rolePlayHandTools = g_currentMission.rolePlay:getHandTools()

	for _, xmlFilename in ipairs(originalHandTools) do
		if rolePlayHandTools[xmlFilename] == nil then
			table.insert(farm.handTools, xmlFilename)
		end
	end

	superFunc(farm, xmlFile, key)

	farm.handTools = originalHandTools
end

local function updateMotorizedActionEvents(vehicle, superFunc)
	if vehicle.spec_motorlessHandTool == nil then
		superFunc(vehicle)

		return
	end

	local automaticMotorStartEnabledBackup = g_currentMission.missionInfo.automaticMotorStartEnabled
	g_currentMission.missionInfo.automaticMotorStartEnabled = true

	superFunc(vehicle)

	g_currentMission.missionInfo.automaticMotorStartEnabled = automaticMotorStartEnabledBackup
end

local function isCuttingAllowed(chainsaw, superFunc, x, y, z, shape)
	local scenario = g_currentMission.rolePlay:getRunningScenarioForFarm(chainsaw.player.farmId)

	if scenario ~= nil and scenario:isa(TreeScenario) then
		return g_currentMission:getHasPlayerPermission("cutTrees")
	end

	return superFunc(chainsaw, x, y, z, shape)
end

local function initGui(settingsFrame, element)
	if not isLoaded() then
		return
	end

	AdditionalSettingsManager.initGui(settingsFrame, element, modEnvironment)
end

local function updateGui(settingsFrame)
	if not isLoaded() then
		return
	end

	AdditionalSettingsManager.updateGui(settingsFrame, modEnvironment)
end

local function saveSettingsToXML(xmlFile)
	if not isLoaded() then
		return
	end

	if g_currentMission.rolePlay ~= nil and g_currentMission.rolePlay.settings ~= nil then
		AdditionalSettingsManager.saveToXMLFile(g_currentMission.rolePlay.settings)
	end
end

local function init()
	FSBaseMission.delete = Utils.prependedFunction(FSBaseMission.delete, unload)
	Mission00.load = Utils.prependedFunction(Mission00.load, load)
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
	FSBaseMission.onConnectionFinishedLoading = Utils.overwrittenFunction(FSBaseMission.onConnectionFinishedLoading, onConnectionFinishedLoading)
	Farm.saveToXMLFile = Utils.overwrittenFunction(Farm.saveToXMLFile, farmSaveToXMLFile)
	Motorized.updateActionEvents = Utils.overwrittenFunction(Motorized.updateActionEvents, updateMotorizedActionEvents)
	PlayerStateCycleHandtool.activate = Utils.overwrittenFunction(PlayerStateCycleHandtool.activate, playerStateCycleHandtoolActivate)
	Utils.getFilename = Utils.overwrittenFunction(Utils.getFilename, FileExtensions.getFilename)
	Chainsaw.isCuttingAllowed = Utils.overwrittenFunction(Chainsaw.isCuttingAllowed, isCuttingAllowed)
	InGameMenuGeneralSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.onFrameOpen, initGui)
	InGameMenuGeneralSettingsFrame.updateGeneralSettings = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.updateGeneralSettings, updateGui)
	GameSettings.saveToXMLFile = Utils.appendedFunction(GameSettings.saveToXMLFile, saveSettingsToXML)
end

if not isRunByTool then
	init()
end
