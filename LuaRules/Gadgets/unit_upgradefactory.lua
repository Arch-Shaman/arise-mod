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
local costFactor         = 2       -- how much more expensive factories are per level, in terms of initial cost.
local maxlevel           = 10      -- maximum level that can be obtained.
local payForNewFactories = false   -- set to true to make cons pay for new factory.
local upgradeFactor      = 0.1     -- percentage boost.
local upgradeTimeMax     = 60      -- in seconds

-- Includes --
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

-- Speedups --
local INLOS = {inlos = true}

local morphCmdDesc = {
	id	   = 323232,
	type   = CMDTYPE.ICON,
	name   = 'Morph',
	action = 'morph',
}

local function GetCost(unitDefID, level)
	return UnitDefs[unitDefID].metalCost * (1 + (costFactor * (level - 1))) -- cost Table: 1 / 3 / 5 / 7 / 9 . .
end

local function GetUnitLevel(unitID)
	return Spring.GetUnitRulesParam(unitID, "unitlevel")
end

local function GetMorphRate(unitDefID, level)
	local actualCost = GetCost(unitDefID, level + 1) - GetCost(unitDefID, level)
	return math.min(actualCost / 10, upgradeTimeMax)
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
		local upgradeAmount = 1 + ((level - 1) * upgradeFactor)
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

local function AddMorphDesc(unitID)
	
end

local function ProcessMorph(unitID)
	
end

local function UpdateMorphDesc(unitID)
	local level = GetUnitLevel(unitID)
	if level == maxlevel then
		-- remove morph command.
	end
end

local function OnMorphComplete(unitID)
	local level = GetUnitLevel(unitID)
	UpdateUnitStats(unitID, level + 1)
	UpdateMorphDesc(unitID)
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if builderID then
		local level = Spring.GetUnitRulesParam(builderID, "unitlevel") or 1
		Spring.SetUnitRulesParam(unitID, "unitlevel", level, INLOS)
		if payForNewFactories and UnitDefs[unitDefID].isFactory then
			UpdateUnitCost(unitID, unitDefID, level)
		end
		UpdateUnitStats(unitID, level)
	end
	if UnitDefs[unitDefID].isFactory then
		AddMorphDesc(unitID)
	end
end

function gadget:UnitDestroyed(unitID)
	
end

function gadget:UnitReverseBuilt(unitID)
	gadget:UnitDestroyed(unitID)
end

function gadget:GameFrame(f)
	
end
