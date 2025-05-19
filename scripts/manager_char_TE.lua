--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals onStrengthChanged onEncumbranceLimitChanged

---	Determine the total bonus to carrying capacity from effects STR or CARRY
--	@param rActor a table containing relevant paths and information on this PC
--	@return nStrEffectMod the PC's current strength score after all bonuses are applied
local function getStrEffectBonus(rActor, nodeChar)
	if not rActor then
		return 0
	end

	local nStrEffectMod = EffectManager35EDS.getEffectsBonus(rActor, 'CARRY', true)
	if EffectManager35EDS.hasEffectCondition(rActor, 'Exhausted') then
		nStrEffectMod = nStrEffectMod - 6
	elseif EffectManager35EDS.hasEffectCondition(rActor, 'Fatigued') then
		nStrEffectMod = nStrEffectMod - 2
	end
	-- include STR effects in calculating carrying capacity
	if not DataCommon.isPFRPG() then
		nStrEffectMod = nStrEffectMod + (EffectManager35EDS.getEffectsBonus(rActor, 'STR', true) or 0)
	end

	DB.setValue(nodeChar, 'encumbrance.strbonusfromeffects', 'number', nStrEffectMod)

	return nStrEffectMod
end

function onEncumbranceLimitChanged(nodeChar)
	local rActor = ActorManager.resolveActor(nodeChar)

	local nHeavy = 0

	local nStrength = DB.getValue(nodeChar, 'abilities.strength.score', 10)

	local nStrengthDamage = 0
	if not DataCommon.isPFRPG() then
		nStrengthDamage = DB.getValue(nodeChar, 'abilities.strength.damage', 0)
	end

	if DB.getValue(nodeChar, 'encumbrance.stradj', 0) == 0 and CharManager.hasTrait(nodeChar, 'Muscle of the Society') then
		DB.removeHandler(DB.getPath(nodeChar, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
		DB.setValue(nodeChar, 'encumbrance.stradj', 2)
		DB.addHandler(DB.getPath(nodeChar, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
	end

	nStrength = nStrength + getStrEffectBonus(rActor, nodeChar) - nStrengthDamage + DB.getValue(nodeChar, 'encumbrance.stradj', 0)
	if EffectManager35EDS.hasEffectCondition(rActor, 'Paralyzed') then
		nStrength = 0
	end

	if nStrength > 0 then
		if nStrength <= 10 then
			nHeavy = nStrength * 10
		else
			nHeavy = 1.25 * math.pow(2, math.floor(nStrength / 5)) * math.floor((20 * math.pow(2, math.fmod(nStrength, 5) / 5)) + 0.5)
		end
	end

	nHeavy = math.floor(nHeavy * DB.getValue(nodeChar, 'encumbrance.carrymult', 1))

	-- Check for carrying capacity multiplier attached to PC on combat tracker. If found, multiply their carrying capacity.
	local nCarryMult = EffectManager35EDS.getEffectsBonus(rActor, 'CARRYMULT', true) or 0
	if nCarryMult ~= 0 then
		nHeavy = nHeavy * nCarryMult
	end

	local nLight = math.floor(nHeavy / 3)
	local nMedium = math.floor((nHeavy / 3) * 2)
	local nLiftOver = nHeavy
	local nLiftOff = nHeavy * 2
	local nPushDrag = nHeavy * 5

	local nSize = ActorCommonManager.getCreatureSizeDnD3(ActorManager.resolveActor(nodeChar))
	if nSize < 0 then
		local nMult = 0
		if nSize == -1 then
			nMult = 0.75
		elseif nSize == -2 then
			nMult = 0.5
		elseif nSize == -3 then
			nMult = 0.25
		elseif nSize == -4 then
			nMult = 0.125
		end

		nLight = math.floor(((nLight * nMult) * 100) + 0.5) / 100
		nMedium = math.floor(((nMedium * nMult) * 100) + 0.5) / 100
		nHeavy = math.floor(((nHeavy * nMult) * 100) + 0.5) / 100
		nLiftOver = math.floor(((nLiftOver * nMult) * 100) + 0.5) / 100
		nLiftOff = math.floor(((nLiftOff * nMult) * 100) + 0.5) / 100
		nPushDrag = math.floor(((nPushDrag * nMult) * 100) + 0.5) / 100
	elseif nSize > 0 then
		local nMult = math.pow(2, nSize)

		nLight = nLight * nMult
		nMedium = nMedium * nMult
		nHeavy = nHeavy * nMult
		nLiftOver = nLiftOver * nMult
		nLiftOff = nLiftOff * nMult
		nPushDrag = nPushDrag * nMult
	end

	DB.setValue(nodeChar, 'encumbrance.lightload', 'number', nLight)
	DB.setValue(nodeChar, 'encumbrance.mediumload', 'number', nMedium)
	DB.setValue(nodeChar, 'encumbrance.heavyload', 'number', nHeavy)
	DB.setValue(nodeChar, 'encumbrance.liftoverhead', 'number', nLiftOver)
	DB.setValue(nodeChar, 'encumbrance.liftoffground', 'number', nLiftOff)
	DB.setValue(nodeChar, 'encumbrance.pushordrag', 'number', nPushDrag)
end

---	This function checks for special abilities.
local function hasSpecialAbility(nodeChar, sSpecAbil)
	if not nodeChar or not sSpecAbil then
		return false
	end

	local sLowerSpecAbil = string.lower(sSpecAbil)
	for _, vNode in ipairs(DB.getChildList(nodeChar, 'specialabilitylist')) do
		local vLowerSpecAbilName = StringManager.trim(DB.getValue(vNode, 'name', ''):lower())
		if vLowerSpecAbilName and string.find(vLowerSpecAbilName, sLowerSpecAbil, 0) then
			return true
		end
	end
end

local function getSpeedMult(nodeChar)
	local nMult = 1
	local rActor = ActorManager.resolveActor(nodeChar)
	if not rActor then
		return nMult
	end
	if
		ActorHealthManager.isDyingOrDead(rActor)
		or EffectManager35EDS.hasEffectCondition(rActor, 'Grappled')
		or EffectManager35EDS.hasEffectCondition(rActor, 'Paralyzed')
		or EffectManager35EDS.hasEffectCondition(rActor, 'Petrified')
		or EffectManager35EDS.hasEffectCondition(rActor, 'Pinned')
	then
		nMult = 0
	elseif
		EffectManager35EDS.hasEffectCondition(rActor, 'Exhausted')
		or EffectManager35EDS.hasEffectCondition(rActor, 'Entangled')
		--	Check if the character is disabled (at zero remaining hp)
		or ((DB.getValue(nodeChar, 'level', 0) ~= 0) and (DB.getValue(nodeChar, 'hp.total', 0) == DB.getValue(nodeChar, 'hp.wounds', 0)))
	then
		nMult = nMult * 0.5
	end
	if EffectManager35EDS.getEffectsBonus(rActor, 'SPEEDMULT', true) ~= 0 then
		nMult = nMult * EffectManager35EDS.getEffectsBonus(rActor, 'SPEEDMULT', true)
	end

	return nMult
end

--	Summary: Determine the total bonus to character's speed from effects
--	Argument: rActor containing the PC's charsheet and combattracker nodes
--	Return: total bonus to speed from effects formatted as "SPEED: n" in the combat tracker
local function getSpeedEffects(nodeChar)
	local rActor = ActorManager.resolveActor(nodeChar)
	if not rActor then
		return 0
	end

	--	Check if the character has fast movement ability
	local function fastMovement()
		local nReturn = 0

		if hasSpecialAbility(nodeChar, 'Fast Movement') then
			local bEncumberedH = (DB.getValue(nodeChar, 'encumbrance.encumbrancelevel', 0) >= 2)
			local bArmorH = (DB.getValue(nodeChar, 'encumbrance.armortype', 0) == 2)
			if not bEncumberedH and not bArmorH then
				nReturn = 10
				DB.setValue(nodeChar, 'speed.fastmovement', 'number', 10)
			else
				DB.setValue(nodeChar, 'speed.fastmovement', 'number', 0)
			end
		else
			DB.setValue(nodeChar, 'speed.fastmovement', 'number', 0)
		end

		return nReturn
	end

	return fastMovement() + EffectManager35EDS.getEffectsBonus(rActor, 'SPEED', true)
end

--	Summary: Finds the max stat and check penalty penalties based on medium and heavy encumbrance thresholds based on current total encumbrance
--	Argument: number light is medium encumbrance threshold for PC
--	Argument: number medium is heavy encumbrance threshold for PC
--	Argument: number total is current total encumbrance for PC
--	Return: number for max stat penalty based solely on encumbrance (max stat, check penalty)
--	Return: number for check penalty penalty based solely on encumbrance (max stat, check penalty)
local function encumbrancePenalties(nodeChar)
	onEncumbranceLimitChanged(nodeChar)

	local light = DB.getValue(nodeChar, 'encumbrance.lightload', 0)
	local medium = DB.getValue(nodeChar, 'encumbrance.mediumload', 0)
	local heavy = DB.getValue(nodeChar, 'encumbrance.heavyload', 0)
	local total = DB.getValue(nodeChar, CharEncumbranceManager.getEncumbranceField(), 0)

	local nEncumbranceLevel = 0
	local nMaxStat, nCheckPenalty
	if total > (heavy * 2) then -- can't move
		nEncumbranceLevel = 4
		nMaxStat = TEGlobals.nOverloadedMaxStat
		nCheckPenalty = TEGlobals.nHeavyCheckPenalty
	elseif total > heavy and (total <= (heavy * 2)) then -- over-loaded
		nEncumbranceLevel = 3
		nMaxStat = TEGlobals.nOverloadedMaxStat
		nCheckPenalty = TEGlobals.nHeavyCheckPenalty
	elseif total > medium then -- heavy encumbrance
		nEncumbranceLevel = 2
		nMaxStat = TEGlobals.nHeavyMaxStat
		nCheckPenalty = TEGlobals.nHeavyCheckPenalty
	elseif total > light then -- medium encumbrance
		nEncumbranceLevel = 1
		nMaxStat = TEGlobals.nMediumMaxStat
		nCheckPenalty = TEGlobals.nMediumCheckPenalty
	end

	DB.setValue(nodeChar, 'encumbrance.encumbrancelevel', 'number', nEncumbranceLevel)

	return nMaxStat, nCheckPenalty, nEncumbranceLevel
end

local function armorTraining(nodeChar)
	local nFighterLevel = DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), 'level', 0)
	local bArmorTraining = (hasSpecialAbility(nodeChar, 'Armor Training') and nFighterLevel >= 3)
	local bArmorTrainingH = (bArmorTraining and nFighterLevel >= 7)
	local bAdvArmorTraining = (hasSpecialAbility(nodeChar, 'Advanced Armor Training'))

	return nFighterLevel, bArmorTraining, bArmorTrainingH, bAdvArmorTraining
end

--luacheck: globals ItemManager.isArmor ItemManager.isShield
-- luacheck: ignore (cyclomatic complexity)
local function calcItemArmorClass_new(nodeChar)
	local nMainArmorTotal = 0
	local nMainShieldTotal = 0
	local nMainMaxStatBonus = 999
	local nMainCheckPenalty = 0
	local nMainSpellFailure = 0
	local nMainSpeed30 = 0
	local nMainSpeed20 = 0

	-- bmos adding armor types
	local bArmorLM = false
	local bArmorH = false

	for _, vNode in ipairs(DB.getChildList(nodeChar, 'inventorylist')) do
		if DB.getValue(vNode, 'carried', 0) == 2 then
			if ItemManager.isArmor(vNode) then
				local nFighterLevel, bArmorTraining, bArmorTrainingH, bAdvArmorTraining = armorTraining(nodeChar)

				local bID = LibraryData.getIDState('item', vNode, true)

				local bIsShield = ItemManager.isShield(vNode)
				if bIsShield then
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, 'ac', 0) + DB.getValue(vNode, 'bonus', 0)
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, 'ac', 0)
					end
				else
					if bID then
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, 'ac', 0) + DB.getValue(vNode, 'bonus', 0)
					else
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, 'ac', 0)
					end

					local sSubtypeLower = StringManager.trim(DB.getValue(vNode, 'subtype', '')):lower()

					if sSubtypeLower:match('heavy') then
						bArmorH = true
					elseif sSubtypeLower:match('light') or sSubtypeLower:match('medium') then
						bArmorLM = true
					end

					local nItemSpeed30 = DB.getValue(vNode, 'speed30', 0)
					if (nItemSpeed30 > 0) and (nItemSpeed30 < 30) then
						if bArmorLM and bArmorTraining then
							nItemSpeed30 = 30
						end
						if bArmorH and bArmorTrainingH then
							nItemSpeed30 = 30
						end
						if nMainSpeed30 > 0 then
							nMainSpeed30 = math.min(nMainSpeed30, nItemSpeed30)
						else
							nMainSpeed30 = nItemSpeed30
						end
					end
					local nItemSpeed20 = DB.getValue(vNode, 'speed20', 0)
					if (nItemSpeed20 > 0) and (nItemSpeed20 < 30) then
						if bArmorLM and bArmorTraining then
							nItemSpeed20 = 20
						end
						if bArmorH and bArmorTrainingH then
							nItemSpeed20 = 20
						end
						if nMainSpeed20 > 0 then
							nMainSpeed20 = math.min(nMainSpeed20, nItemSpeed20)
						else
							nMainSpeed20 = nItemSpeed20
						end
					end
				end

				local nMaxStatBonus = DB.getValue(vNode, 'maxstatbonus', 0)
				if nMaxStatBonus > 0 then
					if not bIsShield and bArmorTraining then
						if nFighterLevel >= 15 and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 4
						elseif nFighterLevel >= 11 and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 3
						elseif bArmorTrainingH and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 2
						else
							nMaxStatBonus = nMaxStatBonus + 1
						end
					end

					if nMaxStatBonus and nMainMaxStatBonus < 999 then
						nMainMaxStatBonus = math.min(nMainMaxStatBonus, nMaxStatBonus)
					else
						nMainMaxStatBonus = nMaxStatBonus
					end
				else
					for _, v in pairs(TEGlobals.tClumsyArmorTypes) do
						if string.find(string.lower(DB.getValue(vNode, 'name', 0)), string.lower(v)) then
							nMainMaxStatBonus = 0
							break
						end
					end
				end

				local nCheckPenalty = DB.getValue(vNode, 'checkpenalty', 0)
				if nCheckPenalty < 0 then
					if not bIsShield and CharManager.hasTrait(nodeChar, 'Armor Expert') then
						nCheckPenalty = nCheckPenalty + 1
					end
					if not bIsShield and bArmorTraining then
						if nFighterLevel >= 15 and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 4
						elseif nFighterLevel >= 11 and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 3
						elseif bArmorTrainingH and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 2
						else
							nCheckPenalty = nCheckPenalty + 1
						end
					end

					if nCheckPenalty < 0 then
						nMainCheckPenalty = nMainCheckPenalty + nCheckPenalty
					end
				end

				local nSpellFailure = DB.getValue(vNode, 'spellfailure', 0)
				if nSpellFailure > 0 then
					nMainSpellFailure = nMainSpellFailure + nSpellFailure
				end
			end
		end
	end

	if bArmorH then
		DB.setValue(nodeChar, 'encumbrance.armortype', 'number', 2)
	elseif bArmorLM then
		DB.setValue(nodeChar, 'encumbrance.armortype', 'number', 1)
	else
		DB.setValue(nodeChar, 'encumbrance.armortype', 'number', 0)
	end

	--	Bring in encumbrance penalties
	local nEncMaxStatBonus, nEncCheckPenalty, nEncumbranceLevel = encumbrancePenalties(nodeChar)
	if nEncMaxStatBonus then
		nMainMaxStatBonus = math.min(nMainMaxStatBonus, nEncMaxStatBonus)
		DB.setValue(nodeChar, 'encumbrance.maxstatbonusfromenc', 'number', nEncMaxStatBonus)
	else
		DB.setValue(nodeChar, 'encumbrance.maxstatbonusfromenc', 'number', nil)
	end
	if nEncCheckPenalty then
		nMainCheckPenalty = math.min(nMainCheckPenalty, nEncCheckPenalty)
		DB.setValue(nodeChar, 'encumbrance.checkpenaltyfromenc', 'number', nEncCheckPenalty)
	else
		DB.setValue(nodeChar, 'encumbrance.checkpenaltyfromenc', 'number', nil)
	end

	DB.setValue(nodeChar, 'ac.sources.armor', 'number', nMainArmorTotal)
	DB.setValue(nodeChar, 'ac.sources.shield', 'number', nMainShieldTotal)
	DB.setValue(nodeChar, 'encumbrance.armormaxstatbonus', 'number', nMainMaxStatBonus)

	if nMainMaxStatBonus < 999 or nMainCheckPenalty < 0 then
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 0)
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 1)
	else
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 1)
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 0)
	end
	DB.setValue(nodeChar, 'encumbrance.armorcheckpenalty', 'number', nMainCheckPenalty)
	DB.setValue(nodeChar, 'encumbrance.spellfailure', 'number', nMainSpellFailure)

	local nSpeedBase = DB.getValue(nodeChar, 'speed.base', 0)

	-- compute speed including total encumberance speed penalty

	local nSpeedArmor = 0

	local bSlowSteady = CharManager.hasTrait(nodeChar, 'Slow and Steady')

	if not bSlowSteady then
		if (nSpeedBase >= 30) and (nMainSpeed30 > 0) then
			nSpeedArmor = nMainSpeed30 - 30
		elseif (nSpeedBase < 30) and (nMainSpeed20 > 0) then
			nSpeedArmor = nMainSpeed20 - 20
		end

		if nEncumbranceLevel >= 1 then
			local nSpeedPenaltyFromEnc = 0

			local nSpeedTableIndex = nSpeedBase / 5
			nSpeedTableIndex = nSpeedTableIndex + 0.5 - (nSpeedTableIndex + 0.5) % 1

			if TEGlobals.tEncumbranceSpeed[nSpeedTableIndex] then
				nSpeedPenaltyFromEnc = TEGlobals.tEncumbranceSpeed[nSpeedTableIndex] - nSpeedBase
			end

			if (nSpeedArmor ~= 0) and (nSpeedPenaltyFromEnc ~= 0) then
				nSpeedArmor = math.min(nSpeedPenaltyFromEnc, nSpeedArmor)
			elseif nSpeedPenaltyFromEnc ~= 0 then
				nSpeedArmor = nSpeedPenaltyFromEnc
			end
		end
	end
	DB.setValue(nodeChar, 'speed.armor', 'number', nSpeedArmor)

	local nSpeedTotal = (
		nSpeedBase
		+ nSpeedArmor
		+ DB.getValue(nodeChar, 'speed.misc', 0)
		+ DB.getValue(nodeChar, 'speed.temporary', 0)
		+ getSpeedEffects(nodeChar)
	) * getSpeedMult(nodeChar)

	-- speed limits for overloaded characters
	if not bSlowSteady then
		if nEncumbranceLevel == 4 then
			nSpeedTotal = 0
		elseif (nEncumbranceLevel == 3) and (nSpeedTotal > 5) then
			nSpeedTotal = 5
		end
	end

	-- speed cannot be negative
	if nSpeedTotal < 0 then
		nSpeedTotal = 0
	end

	DB.setValue(nodeChar, 'speed.total', 'number', nSpeedTotal)
	DB.setValue(nodeChar, 'speed.final', 'number', nSpeedTotal)
end

local updateEncumbrance_old
local function updateEncumbrance_new(nodeChar, ...)
	updateEncumbrance_old(nodeChar, ...)
	calcItemArmorClass_new(nodeChar)
end

local function onHealthChanged(node)
	calcItemArmorClass_new(DB.getParent(node))
end

local function onSpeedChanged(node)
	calcItemArmorClass_new(DB.getChild(node, '...'))
end

---	This function is called when effect components are changed.
local function onEffectChanged(node)
	local rActor = ActorManager.resolveActor(DB.getChild(node, '....'))
	if ActorManager.isPC(rActor) then
		calcItemArmorClass_new(ActorManager.getCreatureNode(rActor))
	end
end

---	This function is called when effects are removed.
local function onEffectRemoved(node)
	local rActor = ActorManager.resolveActor(DB.getChild(node, '..'))
	if ActorManager.isPC(rActor) then
		calcItemArmorClass_new(ActorManager.getCreatureNode(rActor))
	end
end

function onInit()
	if Session.IsHost then
		DB.addHandler(DB.getPath('charsheet.*.hp'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.wounds'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.speed.base'), 'onUpdate', onSpeedChanged)
		DB.addHandler(DB.getPath('charsheet.*.speed.temporary'), 'onUpdate', onSpeedChanged)

		DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH .. '.effects.*.label'), 'onUpdate', onEffectChanged)
		DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH .. '.effects.*.isactive'), 'onUpdate', onEffectChanged)
		DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH .. '.effects'), 'onChildDeleted', onEffectRemoved)
	end

	updateEncumbrance_old = CharEncumbranceManager.updateEncumbrance
	CharEncumbranceManager.updateEncumbrance = updateEncumbrance_new
	CharManager.calcItemArmorClass = calcItemArmorClass_new
end
