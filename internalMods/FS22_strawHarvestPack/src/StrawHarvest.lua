StrawHarvest = {}
MessageType.STRAW_HARVEST_CRANE_MOUNT_OBJECT = nextMessageTypeId()
local StrawHarvest_mt = Class(StrawHarvest)

function StrawHarvest.new(mission, modDirectory, modName, i18n)
	local self = setmetatable({}, StrawHarvest_mt)
	self.isServer = mission:getIsServer()
	self.isClient = mission:getIsClient()
	self.modDirectory = modDirectory
	self.modName = modName
	self.mission = mission
	self.i18n = i18n

	return self
end

function StrawHarvest:delete()
end

function StrawHarvest.addPelletParticelSystems()
	g_particleSystemManager:addParticleType("PELLET_SMOKE")
	g_particleSystemManager:addParticleType("PELLET")
	g_particleSystemManager:addParticleType("PELLET_MOVE")
end

function StrawHarvest.registerPelletsToDensityMap()
	StrawHarvest.registerPelletToDensityMap("STRAW_PELLETS")
	StrawHarvest.registerPelletToDensityMap("HAY_PELLETS")
end

function StrawHarvest.registerPelletToDensityMap(heightType)
	local maxPhysicalSurfaceAngle = math.rad(38)
	local fillToGroundScale = 1
	local allowsSmoothing = false
	local collisionScale = 1
	local collisionBaseOffset = 0.2
	local minCollisionOffset = 0.2
	local maxCollisionOffset = 0.5
	local densityMapHeightType = g_densityMapHeightManager:addDensityMapHeightType(heightType, maxPhysicalSurfaceAngle, collisionScale, collisionBaseOffset, minCollisionOffset, maxCollisionOffset, fillToGroundScale, allowsSmoothing, false)

	if densityMapHeightType == nil then
		Logging.error(("Could not create the %s height type. The combination of map and mods are not compatible"):format(heightType))
	end
end

function StrawHarvest.installVehicleSpecializations(typeManager, specializationManager, modDirectory, modName)
	local pdlc_goeweilPackIsLoaded = g_modIsLoaded.pdlc_goeweilPack
	local pdlc_vermeerPackIsLoaded = g_modIsLoaded.pdlc_vermeerPack

	for typeName, typeEntry in pairs(typeManager:getTypes()) do
		if not pdlc_goeweilPackIsLoaded and not pdlc_vermeerPackIsLoaded and SpecializationUtil.hasSpecialization(Baler, typeEntry.specializations) then
			typeManager:addSpecialization(typeName, modName .. ".strawHarvestBaleCounter")
		end
	end
end

function StrawHarvest.installPlaceableSpecializations(typeManager, specializationManager, modDirectory, modName)
	for typeName, typeEntry in pairs(typeManager:getTypes()) do
		if SpecializationUtil.hasSpecialization(PlaceableHusbandryStraw, typeEntry.specializations) then
			typeManager:addSpecialization(typeName, modName .. ".husbandryBeddingMulti")
		end
	end
end
