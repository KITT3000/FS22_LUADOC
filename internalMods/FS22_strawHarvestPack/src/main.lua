local isEditor = g_isEditor or false
local isIsIconGenerator = g_iconGenerator ~= nil or false
local isRunByTool = isEditor or isIsIconGenerator
local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"
local modEnvironment = nil
local sourceFiles = {
	"src/gui/hud/StrawHarvestBaleCounterHUDExtension.lua",
	"src/utils/StrawHarvestAnimationUtil.lua",
	"src/objects/StrawHarvestStorageBuffer.lua",
	"src/objects/StrawHarvestPalletizer.lua",
	"src/StrawHarvest.lua",
	"src/overwrites.lua"
}

if not isRunByTool then
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestResetBaleCountEvent.lua")
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestBaleGrabEvent.lua")
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestCoverEvent.lua")
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestCollectBaleEvent.lua")
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestCollectModeEvent.lua")
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestDepartBalesEvent.lua")
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestLoadDummyBaleEvent.lua")
	table.insert(sourceFiles, "src/vehicles/events/StrawHarvestCraneToolsEvent.lua")
end

for _, file in ipairs(sourceFiles) do
	source(modDirectory .. file)
end

local function isLoaded()
	return modEnvironment ~= nil and g_modIsLoaded[modName]
end

local function load(mission)
	assert(modEnvironment == nil)

	modEnvironment = StrawHarvest.new(mission, modName, modDirectory, g_i18n)
	mission.strawHarvest = modEnvironment

	addModEventListener(modEnvironment)
	StrawHarvest.registerPelletsToDensityMap()
	sh_overwrite.load()
	StrawHarvest.addPelletParticelSystems()
end

local function unload()
	if not isLoaded() then
		return
	end

	if GS_IS_CONSOLE_VERSION then
		sh_overwrite.resetOriginalFunctions()
	end

	if modEnvironment ~= nil then
		modEnvironment:delete()

		modEnvironment = nil

		if g_currentMission ~= nil then
			g_currentMission.strawHarvest = nil
		end
	end
end

local function validateTypes(typeManager)
	if g_modIsLoaded[modName] then
		if typeManager.typeName == "vehicle" then
			StrawHarvest.installVehicleSpecializations(typeManager, typeManager.specializationManager, modDirectory, modName)
		end

		if typeManager.typeName == "placeable" then
			StrawHarvest.installPlaceableSpecializations(typeManager, typeManager.specializationManager, modDirectory, modName)
		end

		sh_overwrite.validateTypes(typeManager, typeManager.specializationManager, modDirectory, modName)
	end
end

local function init()
	FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)
	Mission00.load = Utils.prependedFunction(Mission00.load, load)
	TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, validateTypes)

	sh_overwrite.init()
end

if not isRunByTool then
	init()

	g_currentStrawHarvestModName = modName

	function Vehicle:strawHarvest_getModName()
		return modName
	end
end
