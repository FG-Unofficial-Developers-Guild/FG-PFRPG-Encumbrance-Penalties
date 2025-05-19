--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- luacheck: globals onStrengthChanged

local function onEncumbranceLimitChanged(nodeChar)
	CharManagerTE.onEncumbranceLimitChanged(nodeChar)
end

function onStrengthChanged()
	-- Debug.chat(getDatabaseNode())
	onEncumbranceLimitChanged(getDatabaseNode())
	CharManager.calcItemArmorClass(getDatabaseNode())
end

function onInit()
	onEncumbranceLimitChanged(getDatabaseNode())

	local nodePC = getDatabaseNode()
	DB.addHandler(DB.getPath(nodePC, 'abilities.strength'), 'onChildUpdate', onStrengthChanged)
	DB.addHandler(DB.getPath(nodePC, 'size'), 'onUpdate', onEncumbranceLimitChanged)
	DB.addHandler(DB.getPath(nodePC, 'encumbrance.carrymult'), 'onUpdate', onStrengthChanged)
	DB.addHandler(DB.getPath(nodePC, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
end

function onClose()
	local nodePC = getDatabaseNode()
	DB.removeHandler(DB.getPath(nodePC, 'abilities.strength'), 'onChildUpdate', onStrengthChanged)
	DB.removeHandler(DB.getPath(nodePC, 'size'), 'onUpdate', onEncumbranceLimitChanged)
	DB.removeHandler(DB.getPath(nodePC, 'encumbrance.carrymult'), 'onUpdate', onStrengthChanged)
	DB.removeHandler(DB.getPath(nodePC, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
end
