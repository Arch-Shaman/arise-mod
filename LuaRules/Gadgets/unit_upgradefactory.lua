if (not gadgetHandler:IsSyncedCode()) then
	return
end

function gadget:GetInfo()
	return {
		name      = "Factory Upgrades",
		desc      = "",
		author    = "Shaman",
		date      = "16 October 2022",
		license   = "",
		layer     = 1,
		enabled   = true  --  loaded by default?
	}
end

-- configuration --
local rules = VFS.Include("gamedata/arise_rules.lua", nil, VFS.GAME)
local FACTORY_RANGE = VFS.Include("gamedata/unitdefs_pre.lua", nil, VFS.GAME).FACTORY_PLATE_RANGE

-- Speedups --
local INLOS = {inlos = true}

-- variables --
local watchUnitIDs = {} -- holds list of factories, since units can build factories. 

-- toolbox --

local function GetCost(unitDefID, level)
	return UnitDefs[unitDefID].metalCost * (1 + (rules.costFactor * (level - 1))) -- cost Table: 1 / 3 / 5 / 7 / 9 . .
end

local function GetUnitLevel(unitID)
	return Spring.GetUnitRulesParam(unitID, "unitlevel")
end

local function UpdateUnitCost(unitID, unitDefID, level)
	local newCost = GetCost(unitDefID, level)
	Spring.SetUnitCosts(unitID, newCost, newCost, newCost)
end

local function GetNewReload(reloadTime, bonus)
	local frameCount = reloadTime * 30
	frameCount = math.ceil(frameCount / bonus)
	return frameCount / 30
end

local function UpdateUnitStats(unitID, level)
	Spring.SetUnitRulesParam(unitID, "unitlevel", level, INLOS)
	if level > 1 then
		local unitDefID = Spring.GetUnitDefID(unitID)
		local health, maxhealth = Spring.GetUnitHealth(unitID)
		local upgradeAmount = 1 + ((level - 1) * rules.upgradeFactor)
		Spring.SetUnitMaxHealth(unitID, maxhealth * upgradeAmount)
		
		-- update weapon stats --
		local weapons = UnitDefs[unitDefID].weapons or {}
		if #weapons > 0 then
			for i = 1, #weapons do
				local def = WeaponDefs[weapons[i].weaponDef]
				local damages = Spring.GetUnitWeaponDamages(unitID)
				local newDamages = {}
				for k, v in pairs(damages) do
					if k:lower() ~= "paralyzedamagetime" then -- DO NOT CHANGE PARALYSIS TIME! At least until we understand it better.
						if type(k) ~= "table" then
							newDamages[k] = v * upgradeAmount
						else
							newDamages[k] = {}
							for s, p in pairs(damages[k]) do
								newDamages[k][s] = p * upgradeAmount
							end
						end
					else
						newDamages[k] = v
					end
				end
				Spring.SetUnitWeaponDamages(unitID, i, newDamages)
				-- Upgrade range --
				local newRange = def.range * upgradeAmount
				local wantedRangeMult = def.customParams.combatrange and (def.customParams.combatrange / def.range)
				if wantedRangeMult then
					Spring.SetUnitMaxRange(unitID, wantedRangeMult * newRange)
				end
				Spring.SetUnitWeaponState(unitID, i, "range", newRange)
				Spring.SetUnitWeaponState(unitID, i, "reloadTime", GetNewReload(def.reload, upgradeAmount))
			end
		end
	end
end

local function UpgradePlatesInRegion(unitID, factoryBaseDef, newLevel, factoryID)
	local allyTeam = Spring.GetUnitAllyTeam(factoryID)
	
end

-- Callins --

function gadget:UnitFinished(unitID, unitDefID, unitTeam)

end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if builderID then
		local level = Spring.GetUnitRulesParam(builderID, "unitlevel") or 1
		Spring.SetUnitRulesParam(unitID, "unitlevel", level, INLOS)
		if rules.payForNewFactories and UnitDefs[unitDefID].isFactory then
			UpdateUnitCost(unitID, unitDefID, level)
		end
		UpdateUnitStats(unitID, level)
	end
	if UnitDefs[unitDefID].isFactory then
		AddMorphDesc(unitID)
	end
end
