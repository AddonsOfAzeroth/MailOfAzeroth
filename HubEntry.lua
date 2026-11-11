-- Mail of Azeroth by DinX: its line in the "Addons of Azeroth" minimap list (Hub.lua).
local ADDON, ns = ...

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	C_Timer.After(0, function()
		local hub = _G.AddonsOfAzerothHub
		if not hub then return end
		local MoA = ns.MoA
		hub:Register({
			key = "mail", addon = ADDON,
			click = function() if MoA.Mailbox and MoA.Mailbox.TogglePanel then MoA.Mailbox:TogglePanel() end end,
			right = function() MoA:ToggleConfig() end,
			minimap = function() return MoA.db and MoA.db.minimap end,
		})
		-- our own button: the shared one takes its place
		local own = _G.MailOfAzerothMinimapButton
		if own then own:Hide() own:SetScript("OnShow", own.Hide) end
	end)
end)
