--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- luacheck: globals onValueChanged getName encumbranceColors getValue setColor

function encumbranceColors()
	if window.usearmormaxstatbonus.getValue() == 0 then
		setColor(ColorManager.getUIColor('usage_full'))
	else
		local nodeEnc = DB.getParent(getDatabaseNode())
		local sArmorStat = getName():gsub('armor', '')
		if DB.getValue(nodeEnc, sArmorStat .. 'fromenc') == DB.getValue(nodeEnc, 'armor' .. sArmorStat) then
			setColor(ColorManager.getUIColor('health_wounds_critical'))
		else
			setColor(ColorManager.getUIColor('usage_full'))
		end
	end
end

function onValueChanged(...)
	if super and super.onValueChanged then
		super.onValueChanged(...)
	end
	encumbranceColors()
end

function onInit()
	if super and super.onInit then
		super.onInit()
	end
	onValueChanged()
end
