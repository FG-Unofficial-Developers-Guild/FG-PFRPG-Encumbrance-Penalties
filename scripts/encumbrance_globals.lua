--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	Armor that has a max dex of 0 (I promise this was the only way)
--	luacheck: globals tClumsyArmorTypes
tClumsyArmorTypes = { 'Fortress plate', 'Half-plate', 'Lamellar (iron)', 'Lamellar (stone coat)', 'Splint mail' }

--	process tClumsyArmorTypes to escape and special characters
function onInit()
	local tSpecialCharacters = { '%(', '%)', '%.', '%+', '%-', '%*', '%?', '%[', '%^', '%$' }

	for i, _ in ipairs(tClumsyArmorTypes) do
		tClumsyArmorTypes[i] = string.gsub(tClumsyArmorTypes[i], '%%', '%%%%')

		for _, vv in ipairs(tSpecialCharacters) do
			tClumsyArmorTypes[i] = string.gsub(tClumsyArmorTypes[i], vv, '%' .. vv)
		end
	end
end

--	Change the encumbrance penalties
--	luacheck: globals nOverloadedMaxStat nHeavyMaxStat nHeavyCheckPenalty nMediumMaxStat nMediumCheckPenalty
nOverloadedMaxStat = 0

nHeavyMaxStat = 1
nHeavyCheckPenalty = -6

nMediumMaxStat = 3
nMediumCheckPenalty = -3

--	Encumbered Speed Equivalents to Base Speeds from 5-120
--	luacheck: globals tEncumbranceSpeed
tEncumbranceSpeed = {
	'5',
	'10',
	'10',
	'15',
	'20',
	'20',
	'25',
	'30',
	'30',
	'35',
	'40',
	'40',
	'45',
	'50',
	'50',
	'55',
	'60',
	'60',
	'65',
	'70',
	'70',
	'75',
	'80',
	'80',
}
